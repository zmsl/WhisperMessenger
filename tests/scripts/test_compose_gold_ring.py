import os
import struct
import tempfile
import unittest
import zlib

from scripts import compose_gold_ring


def png_chunks(data):
    """(tag, body) of every chunk of a PNG."""
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    pos = 8
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos : pos + 4])
        yield data[pos + 4 : pos + 8], data[pos + 8 : pos + 8 + length]
        pos += 12 + length


def png_info(data):
    """(width, height, bit depth, color type, raw scanlines) of a PNG."""
    ihdr, idat = None, b""
    for tag, body in png_chunks(data):
        if tag == b"IHDR":
            ihdr = struct.unpack(">IIBB", body[:10])
        elif tag == b"IDAT":
            idat += body
    return ihdr + (zlib.decompress(idat),)


def paeth(left, up, up_left):
    estimate = left + up - up_left
    nearest = min(abs(estimate - left), abs(estimate - up), abs(estimate - up_left))
    if nearest == abs(estimate - left):
        return left
    return up if nearest == abs(estimate - up) else up_left


def unfilter(width, scanlines):
    """(filter type of each row, rows of RGBA bytes) from 8-bit RGBA scanlines, per the PNG spec."""
    stride = width * 4
    kinds, rows, prior = [], [], [0] * stride
    for start in range(0, len(scanlines), stride + 1):
        kind, line = scanlines[start], scanlines[start + 1 : start + 1 + stride]
        row = []
        for i, value in enumerate(line):
            left = row[i - 4] if i >= 4 else 0
            up_left = prior[i - 4] if i >= 4 else 0
            predicted = [0, left, prior[i], (left + prior[i]) // 2, paeth(left, prior[i], up_left)][kind]
            row.append((value + predicted) & 255)
        kinds.append(kind)
        rows.append(row)
        prior = row
    return kinds, rows


def gradient_rows(size):
    return [[v for x in range(size) for v in (x * 3 % 256, y * 3 % 256, (x + y) % 256, 255)] for y in range(size)]


def render(write):
    with tempfile.TemporaryDirectory() as folder:
        path = os.path.join(folder, "art.png")
        write(path)
        with open(path, "rb") as handle:
            return handle.read()


def shipped(name):
    with open(os.path.join("Media", name), "rb") as handle:
        return handle.read()


def art_rows(pixel, size):
    return [[compose_gold_ring.to_byte(v) for x in range(size) for v in pixel(x, y, size)] for y in range(size)]


def glow_rows():
    """The square glow art: mostly flat, so row filters only add noise."""
    return art_rows(compose_gold_ring.square_glow_pixel, compose_gold_ring.GLOW_SIZE)


def unfiltered_idat(rows):
    return zlib.compress(b"".join(b"\x00" + bytes(row) for row in rows), 9)


class PngEncodingTests(unittest.TestCase):
    def written(self, rows):
        return render(lambda path: compose_gold_ring.write_png(path, len(rows[0]) // 4, len(rows), rows))

    def test_write_png_roundtrips_pixels_with_filtered_rows(self):
        rows = gradient_rows(48)
        width, _height, _depth, _color, scanlines = png_info(self.written(rows))
        kinds, decoded = unfilter(width, scanlines)
        self.assertEqual(decoded, rows)
        self.assertTrue(set(kinds) - {0}, "no row was filtered")

    def test_write_png_roundtrips_art_through_sub_up_and_paeth_rows(self):
        rows = art_rows(compose_gold_ring.ring_pixel, 64)
        width, _height, _depth, _color, scanlines = png_info(self.written(rows))
        kinds, decoded = unfilter(width, scanlines)
        self.assertEqual(decoded, rows)
        self.assertEqual(set(kinds), {1, 2, 4})

    def idat_size(self, rows):
        return sum(len(body) for tag, body in png_chunks(self.written(rows)) if tag == b"IDAT")

    def test_filtered_png_is_smaller_than_unfiltered_for_gradient(self):
        rows = gradient_rows(48)
        self.assertLess(self.idat_size(rows), len(unfiltered_idat(rows)))

    def test_png_stays_unfiltered_when_filters_make_it_bigger(self):
        rows = glow_rows()
        self.assertEqual(self.idat_size(rows), len(unfiltered_idat(rows)))

    def test_write_png_keeps_8_bit_rgba_without_interlace(self):
        header = dict(png_chunks(self.written(gradient_rows(8))))[b"IHDR"]
        self.assertEqual(struct.unpack(">IIBBBBB", header), (8, 8, 8, 6, 0, 0, 0))


class RingArtTests(unittest.TestCase):
    def test_shipped_ring_matches_the_generator(self):
        self.assertEqual(
            png_info(render(compose_gold_ring.write_ring)),
            png_info(shipped("ring_gold.png")),
        )

    def test_ring_is_256_square_rgba(self):
        self.assertEqual(png_info(shipped("ring_gold.png"))[:4], (256, 256, 8, 6))


class SquareFrameTests(unittest.TestCase):
    def alpha(self, x, y):
        return compose_gold_ring.square_pixel(x, y, 256)[3]

    def test_square_frame_leaves_a_one_pixel_margin(self):
        self.assertEqual(
            [self.alpha(0, 128), self.alpha(128, 0), self.alpha(255, 128), self.alpha(128, 255)],
            [0, 0, 0, 0],
        )
        self.assertEqual(self.alpha(1, 128), 1.0)

    def test_square_frame_has_square_corners(self):
        self.assertEqual(self.alpha(5, 5), 1.0)
        self.assertEqual(compose_gold_ring.ring_pixel(5, 5, 256)[3], 0.0)  # the ring is clear there

    def test_square_band_is_a_tenth_of_the_side(self):
        self.assertEqual(self.alpha(20, 128), 1.0)
        self.assertEqual(self.alpha(30, 128), 0.0)

    def test_square_hole_edge_is_smoothed_over_one_pixel(self):
        self.assertTrue(0 < self.alpha(26, 128) < 1)

    def test_square_hole_is_clear(self):
        self.assertEqual(self.alpha(128, 128), 0.0)

    def test_square_frame_is_lit_from_the_top_left(self):
        self.assertGreater(
            compose_gold_ring.square_pixel(10, 10, 256)[0],
            compose_gold_ring.square_pixel(245, 245, 256)[0],
        )

    def test_square_mode_writes_a_256_square_rgba_png(self):
        def write(path):
            self.assertEqual(compose_gold_ring.main(["--square", path]), 0)

        self.assertEqual(png_info(render(write))[:4], (256, 256, 8, 6))

    def test_shipped_square_frame_matches_the_generator(self):
        self.assertEqual(
            png_info(render(compose_gold_ring.write_square)),
            png_info(shipped("frame_gold_square.png")),
        )


class RoundedSquareArtTests(unittest.TestCase):
    def test_mask_is_clear_in_the_corner_and_opaque_in_the_centre(self):
        self.assertEqual(compose_gold_ring.square_mask_pixel(0, 0, 256)[3], 0.0)
        self.assertEqual(compose_gold_ring.square_mask_pixel(128, 128, 256)[3], 1.0)

    def test_glow_is_clear_in_the_centre(self):
        self.assertEqual(compose_gold_ring.square_glow_pixel(32, 32, 64)[3], 0.0)

    def test_glow_is_bright_just_inside_the_edge(self):
        alpha = compose_gold_ring.square_glow_pixel(32, 1, 64)[3]
        self.assertTrue(200 / 255 < alpha <= 1.0)

    def test_glow_has_faded_out_well_before_the_centre(self):
        self.assertEqual(compose_gold_ring.square_glow_pixel(32, 20, 64)[3], 0.0)

    def test_rounded_frame_is_clear_in_the_corner(self):
        self.assertEqual(compose_gold_ring.square_rounded_pixel(1, 1, 256)[3], 0.0)

    def test_rounded_frame_is_solid_just_inside_the_corner(self):
        self.assertGreater(compose_gold_ring.square_rounded_pixel(5, 5, 256)[3], 0.9)

    def test_rounded_frame_keeps_the_straight_edges(self):
        self.assertEqual(
            compose_gold_ring.square_rounded_pixel(128, 3, 256),
            compose_gold_ring.square_pixel(128, 3, 256),
        )

    def test_square_glow_mode_writes_a_64_square_rgba_png(self):
        def write(path):
            self.assertEqual(compose_gold_ring.main(["--square-glow", path]), 0)

        self.assertEqual(png_info(render(write))[:4], (64, 64, 8, 6))

    def test_square_mask_mode_writes_a_256_square_rgba_png(self):
        def write(path):
            self.assertEqual(compose_gold_ring.main(["--square-mask", path]), 0)

        self.assertEqual(png_info(render(write))[:4], (256, 256, 8, 6))

    def test_square_rounded_mode_writes_a_256_square_rgba_png(self):
        def write(path):
            self.assertEqual(compose_gold_ring.main(["--square-rounded", path]), 0)

        self.assertEqual(png_info(render(write))[:4], (256, 256, 8, 6))

    def test_shipped_square_glow_matches_the_generator(self):
        self.assertEqual(
            png_info(render(compose_gold_ring.write_square_glow)),
            png_info(shipped("inner-glow-square.png")),
        )

    def test_shipped_square_mask_matches_the_generator(self):
        self.assertEqual(
            png_info(render(compose_gold_ring.write_square_mask)),
            png_info(shipped("mask_rounded_square.png")),
        )

    def test_shipped_rounded_frame_matches_the_generator(self):
        self.assertEqual(
            png_info(render(compose_gold_ring.write_square_rounded)),
            png_info(shipped("frame_gold_square_rounded.png")),
        )



class HandleArtTests(unittest.TestCase):
    """The edge handle's art: 22 x 104 px in game, drawn on a 64 x 256 canvas, flat side on x = 0."""

    G = compose_gold_ring
    SX = G.HANDLE_WIDTH / G.HANDLE_CANVAS_W  # display px per texel, across
    SY = G.HANDLE_HEIGHT / G.HANDLE_CANVAS_H  # and down

    def band_across(self, pixel, y):
        """Display px of solid rim on texel row y."""
        return sum(1 for x in range(self.G.HANDLE_CANVAS_W) if pixel(x, y)[3] > 0.5) * self.SX

    def band_down(self, pixel, x):
        """Display px of solid rim in the top half of texel column x."""
        return sum(1 for y in range(self.G.HANDLE_CANVAS_H // 2) if pixel(x, y)[3] > 0.5) * self.SY

    def test_capsule_rim_keeps_one_band_width_at_the_tip_and_the_ends(self):
        tip = self.band_across(self.G.handle_capsule_pixel, self.G.HANDLE_CANVAS_H // 2)
        end = self.band_down(self.G.handle_capsule_pixel, 0)
        self.assertAlmostEqual(tip, self.G.HANDLE_CAPSULE_BAND, delta=0.5)
        self.assertAlmostEqual(end, self.G.HANDLE_CAPSULE_BAND, delta=0.5)

    def test_capsule_is_clear_inside_and_in_the_outer_corners(self):
        self.assertEqual(self.G.handle_capsule_pixel(10, 128)[3], 0.0)
        self.assertEqual(self.G.handle_capsule_pixel(63, 0)[3], 0.0)

    def test_capsule_mask_fills_to_mid_band(self):
        self.assertEqual(self.G.handle_capsule_mask_pixel(10, 128)[3], 1.0)
        self.assertEqual(self.G.handle_capsule_mask_pixel(63, 128)[3], 0.0)
        self.assertEqual(self.G.handle_capsule_mask_pixel(63, 0)[3], 0.0)

    def test_tab_rim_keeps_the_square_band_on_both_sides(self):
        side = self.band_across(self.G.handle_tab_pixel, self.G.HANDLE_CANVAS_H // 2)
        top = self.band_down(self.G.handle_tab_pixel, 0)
        self.assertAlmostEqual(side, self.G.HANDLE_TAB_BAND, delta=0.5)
        self.assertAlmostEqual(top, self.G.HANDLE_TAB_BAND, delta=0.5)

    def test_tab_has_a_sharp_inner_corner_and_the_rounded_tab_a_round_one(self):
        self.assertGreater(self.G.handle_tab_pixel(63, 0)[3], 0.4)
        self.assertEqual(self.G.handle_tab_rounded_pixel(63, 0)[3], 0.0)
        for a, b in zip(self.G.handle_tab_rounded_pixel(30, 2), self.G.handle_tab_pixel(30, 2)):
            self.assertAlmostEqual(a, b)

    def test_rims_are_lit_from_the_top(self):
        self.assertGreater(self.G.handle_capsule_pixel(5, 2)[0], self.G.handle_capsule_pixel(5, 253)[0])

    def check_mode(self, mode):
        def write(path):
            self.assertEqual(self.G.main([mode, path]), 0)

        self.assertEqual(png_info(render(write))[:4], (64, 256, 8, 6))

    def test_handle_modes_write_64_by_256_rgba_pngs(self):
        for mode in ("--handle-capsule", "--handle-capsule-mask", "--handle-tab", "--handle-tab-rounded"):
            self.check_mode(mode)

    def test_handle_preview_mode_writes_an_rgba_png(self):
        def write(path):
            self.assertEqual(self.G.main(["--handle-preview", path]), 0)

        self.assertEqual(png_info(render(write))[2:4], (8, 6))

    def test_shipped_handle_art_matches_the_generator(self):
        for write, name in (
            (self.G.write_handle_capsule, "handle_capsule_gold.png"),
            (self.G.write_handle_capsule_mask, "handle_capsule_mask.png"),
            (self.G.write_handle_tab, "handle_tab_gold.png"),
            (self.G.write_handle_tab_rounded, "handle_tab_gold_rounded.png"),
        ):
            self.assertEqual(png_info(render(write)), png_info(shipped(name)), name)

if __name__ == "__main__":
    unittest.main()
