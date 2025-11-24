import telegram
from database import store_chat


async def send_telegram_notification(
    bot_token: str, chat_id: str, message: str
) -> None:
    """
    Sends a notification via Telegram bot.

    Args:
        bot_token: The Telegram bot token.
        chat_id: The chat ID to send the message to.
        message: The message to send.
    """
    bot = telegram.Bot(token=bot_token)

    async with bot:
        await bot.send_message(chat_id=chat_id, text=message)
        print("Notification sent successfully!")


async def get_chat_ids(bot_token: str) -> None:
    """
    Gets chat IDs from recent bot interactions.

    Args:
        bot_token: The Telegram bot token.
    """
    bot = telegram.Bot(token=bot_token)
    async with bot:
        updates = await bot.get_updates()
        if not updates:
            print("No new messages found.")
            return

        chats = {
            update.message.chat.id: update.message.chat
            for update in updates
            if update.message and update.message.chat
        }

        if chats:
            print("Found chats:")
            for chat_id, chat in chats.items():
                name = chat.first_name
                if chat.last_name:
                    name += f" {chat.last_name}"
                store_chat(chat_id, name)
                print(f"Stored Chat ID: {chat_id}, Name: {name}")
        else:
            print("No chats found in recent messages.")
