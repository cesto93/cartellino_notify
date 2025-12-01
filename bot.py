import asyncio
import os
from datetime import datetime
import re
from telegram import ReplyKeyboardMarkup, KeyboardButton, Update, Bot
from telegram.ext import (
    Application,
    CommandHandler,
    ContextTypes,
    ConversationHandler,
    MessageHandler,
    filters,
)
from actions import work_end
from cartellino import seconds_to_turn_end, turn_end_time, seconds_to_liquidatable_overtime
from database import (
    get_daily_setting,
    get_setting,
    get_start_time,
    store_start_time,
    store_daily_setting,
)


def get_keyboard(chat_id: int) -> ReplyKeyboardMarkup:
    """Restituisce la tastiera in base allo stato dell'utente."""
    keyboard = [
        [
            KeyboardButton("Set Start Time"),
            KeyboardButton("Set Leisure Time"),
        ],
    ]
    if get_start_time(chat_id):
        keyboard[0].insert(0, KeyboardButton("Work End"))
        keyboard.append([KeyboardButton("Notify Liquidated Overtime")])
    else:
        keyboard[0].insert(0, KeyboardButton("I'm Arrived"))
    return ReplyKeyboardMarkup(keyboard, resize_keyboard=True)


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Invia un messaggio di benvenuto quando viene eseguito il comando /start."""
    if not update.message:
        return
    chat_id = update.message.chat_id
    reply_markup = get_keyboard(chat_id)
    await update.message.reply_text(
        "Ciao! Sono il cartellino bot. Usa il pulsante qui sotto per sapere quando finisce il turno di lavoro.",
        reply_markup=reply_markup,
    )


async def handle_work_end(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Gestisce il pulsante Work End."""
    if not update.message:
        return

    chat_id = update.message.chat_id
    await update.message.reply_text("Eseguo il comando work-end...")
    output = work_end(chat_id)
    await update.message.reply_text(
        f"<pre>{output}</pre>",
        parse_mode="HTML",
    )


async def handle_im_arrived(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handles the I'm Arrived button - sets start time to current time."""
    if not update.message:
        return

    chat_id = update.message.chat_id
    start_time = get_start_time(chat_id)
    
    if start_time:
        await update.message.reply_text(
            f"L'orario di inizio è già impostato per oggi: {start_time}"
        )
        return
    
    # Get current time in HH:MM format
    current_time = datetime.now().strftime("%H:%M")
    store_start_time(chat_id, current_time)
    
    reply_markup = get_keyboard(chat_id)
    await update.message.reply_text(
        f"Benvenuto! Orario di inizio impostato su: {current_time}",
        reply_markup=reply_markup,
    )
    
    await notify_work_turn(update, context)


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


async def notify_liquidated_overtime(delay: float, bot_token: str, chat_id: str) -> None:
    """Sends a notification when liquidated overtime threshold is reached."""
    message = "⏰ Liquidated overtime threshold reached! (30 minutes after work end)"
    await asyncio.sleep(delay)
    await send_telegram_notification(bot_token, chat_id, message)


async def ask_for_start_time(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    """Asks for the start time."""
    if not update.message:
        return ConversationHandler.END
    chat_id = update.message.chat_id
    start_time = get_start_time(chat_id)
    if start_time:
        await update.message.reply_text(
            f"L'orario di inizio è già impostato per oggi: {start_time}"
        )
        return ConversationHandler.END
    else:
        await update.message.reply_text(
            "Ciao! Per favore, inserisci l'orario di inizio nel formato 'HH:MM'."
        )
    return AWAIT_START_TIME


async def handle_start_time(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    """Handles the start time provided by the user."""
    if not update.message or not update.message.text:
        return ConversationHandler.END
    message_text = update.message.text
    if not re.match(r"^\d{2}:\d{2}$", message_text):
        await update.message.reply_text(
            "Formato non valido. Per favore, inserisci l'orario come 'HH:MM'."
        )
        return AWAIT_START_TIME
    chat_id = update.message.chat_id
    store_start_time(chat_id, message_text)
    
    reply_markup = get_keyboard(chat_id)
    if update.message:
        await update.message.reply_text(
            f"Orario di inizio impostato su: {message_text}",
            reply_markup=reply_markup,
        )

    await notify_work_turn(update, context)
    return ConversationHandler.END


async def ask_for_leisure_time(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    """Asks for the leisure time."""
    if not update.message:
        return ConversationHandler.END
    await update.message.reply_text(
        "Inserisci il tempo di svago nel formato 'HH:MM'."
    )
    return AWAIT_LEISURE_TIME


async def handle_leisure_time(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    """Handles the leisure time provided by the user."""
    if not update.message or not update.message.text:
        return ConversationHandler.END
    message_text = update.message.text
    if not re.match(r"^\d{2}:\d{2}$", message_text):
        await update.message.reply_text(
            "Formato non valido. Per favore, inserisci l'orario come 'HH:MM'."
        )
        return AWAIT_LEISURE_TIME
    chat_id = update.message.chat_id
    store_daily_setting(chat_id, "leisure_time", message_text)
    
    reply_markup = get_keyboard(chat_id)
    if update.message:
        await update.message.reply_text(
            f"Tempo di svago impostato su: {message_text}",
            reply_markup=reply_markup,
        )

    await notify_work_turn(update, context)
    return ConversationHandler.END


async def notify_work_turn(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    if not update.message:
        return
    chat_id = update.message.chat_id
    start_time = get_start_time(chat_id)
    if not start_time:
        await update.message.reply_text(
            "L'orario di inizio non è impostato. Per favore, usa /start per impostarlo."
        )
        return

    wt = get_setting("work_time") or "07:12"
    lt = get_setting("lunch_time") or "00:30"
    lrt = get_daily_setting(chat_id, "leisure_time")

    finish_time = turn_end_time(start_time, wt, lt, lrt)
    await update.message.reply_text(
        f"Attenderò fino alla fine del turno di lavoro e ti notificherò alle {finish_time}."
    )
    remaining_seconds = seconds_to_turn_end(start_time, wt, lt, lrt)
    print(f"Remaining seconds: {remaining_seconds}")

    bot_token = os.getenv("TELEGRAM_BOT_TOKEN")
    loop = asyncio.get_event_loop()
    if bot_token and chat_id:
        loop.create_task(notify_work_end(remaining_seconds, bot_token, str(chat_id)))


async def handle_notify_liquidated_overtime(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handles the Notify Liquidated Overtime button."""
    if not update.message:
        return

    chat_id = update.message.chat_id
    start_time = get_start_time(chat_id)
    
    if not start_time:
        await update.message.reply_text(
            "L'orario di inizio non è impostato. Per favore, imposta prima l'orario di inizio."
        )
        return

    wt = get_setting("work_time") or "07:12"
    lt = get_setting("lunch_time") or "00:30"
    lrt = get_daily_setting(chat_id, "leisure_time")

    remaining_seconds = seconds_to_liquidatable_overtime(start_time, wt, lt, lrt)
    
    if remaining_seconds <= 0:
        await update.message.reply_text(
            "La soglia di straordinario liquidabile è già stata raggiunta!"
        )
        return
    
    # Calculate the time when liquidated overtime will be reached
    from datetime import datetime, timedelta
    liquidated_time = datetime.now() + timedelta(seconds=remaining_seconds)
    liquidated_time_str = liquidated_time.strftime("%H:%M")
    
    await update.message.reply_text(
        f"Ti notificherò quando verrà raggiunta la soglia di straordinario liquidabile alle {liquidated_time_str} (30 minuti dopo la fine del turno)."
    )
    
    bot_token = os.getenv("TELEGRAM_BOT_TOKEN")
    loop = asyncio.get_event_loop()
    if bot_token and chat_id:
        loop.create_task(notify_liquidated_overtime(remaining_seconds, bot_token, str(chat_id)))


AWAIT_START_TIME = 0
AWAIT_LEISURE_TIME = 1


def start_bot() -> None:
    """Avvia il bot."""
    bot_token = os.getenv("TELEGRAM_BOT_TOKEN")
    if not bot_token:
        raise ValueError("La variabile d'ambiente TELEGRAM_BOT_TOKEN non è impostata.")

    application = Application.builder().token(bot_token).build()

    conv_handler = ConversationHandler(
        entry_points=[
            CommandHandler("set_start", ask_for_start_time),
            MessageHandler(filters.Regex("^Set Start Time$"), ask_for_start_time),
            MessageHandler(filters.Regex("^Set Leisure Time$"), ask_for_leisure_time),
        ],
        states={
            AWAIT_START_TIME: [
                MessageHandler(filters.TEXT & ~filters.COMMAND, handle_start_time)
            ],
            AWAIT_LEISURE_TIME: [
                MessageHandler(filters.TEXT & ~filters.COMMAND, handle_leisure_time)
            ],
        },
        fallbacks=[CommandHandler("start", start)],
    )

    application.add_handler(CommandHandler("start", start))
    application.add_handler(conv_handler)
    application.add_handler(MessageHandler(filters.Regex("^Work End$"), handle_work_end))
    application.add_handler(MessageHandler(filters.Regex("^I'm Arrived$"), handle_im_arrived))
    application.add_handler(MessageHandler(filters.Regex("^Notify Liquidated Overtime$"), handle_notify_liquidated_overtime))

    print("Bot started. Listening for commands...")
    application.run_polling()
