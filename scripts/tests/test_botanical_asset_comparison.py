import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from generate_botanical_watercolor_assets import asset_contents_match


class AssetComparisonTests(unittest.TestCase):
    def test_different_png_compression_preserves_pixels(self):
        with tempfile.TemporaryDirectory() as directory:
            expected, actual = [Path(directory) / name for name in ("expected.png", "actual.png")]
            picture = Image.new("RGBA", (20, 20), (20, 60, 40, 180))
            picture.save(expected, compress_level=0)
            picture.save(actual, compress_level=9)
            self.assertNotEqual(expected.read_bytes(), actual.read_bytes())
            self.assertTrue(asset_contents_match(expected, actual))
            picture.putpixel((0, 0), (20, 60, 41, 180))
            picture.save(actual)
            self.assertFalse(asset_contents_match(expected, actual))
            actual.write_bytes(b"broken PNG")
            self.assertFalse(asset_contents_match(expected, actual))


if __name__ == "__main__":
    unittest.main()
