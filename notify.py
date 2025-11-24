import telegram
from telegram.error import TelegramError


def send_telegram_notification(bot_token: str, chat_id: str, message: str) -> None:
    """
    Sends a notification via Telegram bot.

    Args:
        bot_token: The Telegram bot token.
        chat_id: The chat ID to send the message to.
        message: The message to send.
    """
    bot = telegram.Bot(token=bot_token)

    try:
        bot.send_message(chat_id=chat_id, text=message)
        print("Notification sent successfully!")
    except TelegramError as e:
        print(f"Failed to send notification: {e}")


if __name__ == "__main__":
    # Example usage (replace with your actual bot token and chat ID)
    bot_token = "YOUR_BOT_TOKEN"
    chat_id = "YOUR_CHAT_ID"
    message = "Work time is over!"
    send_telegram_notification(bot_token, chat_id, message)
