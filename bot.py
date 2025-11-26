import asyncio
import os
import re
from telegram import InlineKeyboardButton, InlineKeyboardMarkup, Update, Bot
from telegram.ext import (
    Application,
    CommandHandler,
    CallbackQueryHandler,
    ContextTypes,
    ConversationHandler,
    MessageHandler,
    filters,
)
from actions import work_end
from cartellino import get_remaining_seconds, turn_end_time
from database import (
    get_daily_setting,
    get_setting,
    get_start_time,
    store_chat,
    store_start_time,
)


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Invia un messaggio di benvenuto quando viene eseguito il comando /start."""
    keyboard = [
        [InlineKeyboardButton("work-end", callback_data="work_end_data")],
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    if update.message:
        await update.message.reply_text(
            "Ciao! Sono il cartellino bot. Usa il pulsante qui sotto per sapere quando finisce il turno di lavoro.",
            reply_markup=reply_markup,
        )


async def button_callback(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Analizza la CallbackQuery e gestisce il pulsante premuto."""
    query = update.callback_query
    if not query:
        return

    await (
        query.answer()
    )  # Risponde alla callback per far sparire l'icona di caricamento

    if query.data == "work_end_data":
        await query.edit_message_text(text="Eseguo il comando work-end...")
        # Esegue il comando CLI 'work-end'
        output = work_end()
        if query.message is None:
            return
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
                if name is None:
                    name = chat.username or "Unknown"
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


async def ask_for_start_time(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    """Asks for the start time only if it's not already stored."""
    start_time = get_start_time()
    if start_time:
        await update.message.reply_text(
            f"L'orario di inizio è già impostato per oggi: {start_time}"
        )
        return NOTIFY_WORK_TURN
    else:
        if update.message:
            await update.message.reply_text(
                "Ciao! Per favore, inserisci l'orario di inizio nel formato 'HH:MM'."
            )
    return AWAIT_START_TIME


async def handle_start_time(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    """Handles the start time provided by the user."""
    message_text = update.message.text if update.message else ""
    if message_text is None or not re.match(r"^\d{2}:\d{2}$", message_text):
        if update.message:
            await update.message.reply_text(
                "Formato non valido. Per favore, inserisci l'orario come 'HH:MM'."
            )
        return AWAIT_START_TIME

    store_start_time(message_text)
    if update.message:
        await update.message.reply_text(
            f"Orario di inizio impostato su: {message_text}"
        )

    return NOTIFY_WORK_TURN


async def notify_work_turn(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    start_time = get_start_time()
    if not start_time:
        await update.message.reply_text(
            "L'orario di inizio non è impostato. Per favore, usa /start per impostarlo."
        )
        return ConversationHandler.END

    wt = get_setting("work_time") or "07:12"
    lt = get_setting("lunch_time") or "00:30"
    lrt = get_daily_setting("leisure_time")

    finish_time = turn_end_time(start_time, wt, lt, lrt)
    await update.message.reply_text(
        f"Attenderò fino alla fine del turno di lavoro e ti notificherò alle {finish_time}."
    )
    remaining_seconds = get_remaining_seconds(start_time, wt, lt, lrt)
    print(f"Remaining seconds: {remaining_seconds}")
    bot_token = os.getenv("TELEGRAM_BOT_TOKEN")
    loop = asyncio.get_event_loop()
    chat_id = os.getenv("TELEGRAM_CHAT_ID")
    if bot_token and chat_id:
        loop.create_task(notify_work_end(remaining_seconds, bot_token, chat_id))
    return ConversationHandler.END


AWAIT_START_TIME = 0
NOTIFY_WORK_TURN = 1


def start_bot() -> None:
    """Avvia il bot."""
    bot_token = os.getenv("TELEGRAM_BOT_TOKEN")
    if not bot_token:
        raise ValueError("La variabile d'ambiente TELEGRAM_BOT_TOKEN non è impostata.")

    application = Application.builder().token(bot_token).build()

    conv_handler = ConversationHandler(
        entry_points=[CommandHandler("start", ask_for_start_time)],
        states={
            AWAIT_START_TIME: [
                MessageHandler(filters.TEXT & ~filters.COMMAND, handle_start_time)
            ],
        },
        fallbacks=[],
    )

    application.add_handler(conv_handler)
    application.add_handler(CallbackQueryHandler(button_callback))

    print("Bot started. Listening for commands...")
    application.run_polling()
