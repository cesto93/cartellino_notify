import os
import sys
import argparse

from dotenv import load_dotenv

import telegram
import asyncio


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

        chat_ids = {
            update.message.chat.id
            for update in updates
            if update.message and update.message.chat
        }

        if chat_ids:
            print("Found chat IDs:")
            for chat_id in chat_ids:
                print(chat_id)
        else:
            print("No chat IDs found in recent messages.")
