import asyncio
import os
from telegram import InlineKeyboardButton, InlineKeyboardMarkup, Update, Bot
from telegram.ext import (
    Application,
    CommandHandler,
    CallbackQueryHandler,
    ContextTypes,
)
from actions import work_end
from cartellino import get_remaining_seconds
from database import store_chat


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Invia un messaggio di benvenuto quando viene eseguito il comando /start."""
    keyboard = [
        [InlineKeyboardButton("work-end", callback_data="work_end_data")],
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    await update.message.reply_text(
        "Ciao! Sono il cartellino bot. Usa il pulsante qui sotto per sapere quando finisce il turno di lavoro.",
        reply_markup=reply_markup,
    )


async def button_callback(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Analizza la CallbackQuery e gestisce il pulsante premuto."""
    query = update.callback_query
    await (
        query.answer()
    )  # Risponde alla callback per far sparire l'icona di caricamento

    if query.data == "work_end_data":
        await query.edit_message_text(text="Eseguo il comando work-end...")
        # Esegue il comando CLI 'work-end'
        output = work_end()
        # Invia l'output del comando come nuovo messaggio
        await query.message.reply_text(
            f"<pre>{output}</pre>",
            parse_mode="HTML",
        )


async def get_chat_ids(bot_token: str) -> None:
    """
    Gets chat IDs from recent bot interactions.

    Args:
        bot_token: The Telegram bot token.
    """
    bot = Bot(token=bot_token)
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
    bot = Bot(token=bot_token)

    async with bot:
        await bot.send_message(chat_id=chat_id, text=message)
        print("Notification sent successfully!")


async def notify_work_end(delay: float, bot_token: str, chat_id: str) -> None:
    message = "Work time is over!"
    await asyncio.sleep(delay)
    await send_telegram_notification(bot_token, chat_id, message)


def start_bot(
    start_time: str, work_time: str, lunch_time: str, leisure_time: str | None
) -> None:
    """Avvia il bot."""
    bot_token = os.getenv("TELEGRAM_BOT_TOKEN")
    if not bot_token:
        raise ValueError("La variabile d'ambiente TELEGRAM_BOT_TOKEN non è impostata.")
    chat_id = os.getenv("TELEGRAM_CHAT_ID")
    if not chat_id:
        raise ValueError("La variabile d'ambiente TELEGRAM_CHAT_ID non è impostata.")

    application = Application.builder().token(bot_token).build()

    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(button_callback))

    remaining_seconds = get_remaining_seconds(
        start_time, work_time, lunch_time, leisure_time
    )
    print(f"Remaining seconds: {remaining_seconds}")

    loop = asyncio.get_event_loop()
    loop.create_task(notify_work_end(remaining_seconds, bot_token, chat_id))

    print("Bot started. Listening for commands...")
    application.run_polling()
