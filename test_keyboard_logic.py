import unittest
from unittest.mock import patch, MagicMock
import sys
import os

# Add current directory to path
sys.path.append(os.getcwd())

# Mock telegram module before importing bot
sys.modules["telegram"] = MagicMock()
sys.modules["telegram.ext"] = MagicMock()

# Import bot
import bot

class TestKeyboardLogic(unittest.TestCase):
    @patch("bot.get_start_time")
    def test_keyboard_without_start_time(self, mock_get_start_time):
        mock_get_start_time.return_value = None
        
        with patch("bot.ReplyKeyboardMarkup") as MockMarkup:
            bot.get_keyboard(123)
            args, _ = MockMarkup.call_args
            keyboard = args[0]
            # Should have 2 buttons: Set Start Time, Set Leisure Time
            self.assertEqual(len(keyboard[0]), 2)

    @patch("bot.get_start_time")
    def test_keyboard_with_start_time(self, mock_get_start_time):
        mock_get_start_time.return_value = "09:00"
        
        with patch("bot.ReplyKeyboardMarkup") as MockMarkup:
            bot.get_keyboard(123)
            args, _ = MockMarkup.call_args
            keyboard = args[0]
            # Should have 3 buttons: Work End, Set Start Time, Set Leisure Time
            self.assertEqual(len(keyboard[0]), 3)

if __name__ == "__main__":
    unittest.main()
