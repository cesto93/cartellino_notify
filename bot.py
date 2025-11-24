import os
from telegram import InlineKeyboardButton, InlineKeyboardMarkup, Update
from telegram.ext import (
    Application,
    CommandHandler,
    CallbackQueryHandler,
    ContextTypes,
)
from dotenv import load_dotenv
from actions import work_end


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Invia un messaggio di benvenuto quando viene eseguito il comando /start."""
    keyboard = [
        [InlineKeyboardButton("work-end", callback_data="work_end_data")],
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    await update.message.reply_text(
        "Ciao! Sono il tuo bot per la timbratura. Usa il pulsante qui sotto per timbrare l'uscita.",
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


def main() -> None:
    """Avvia il bot."""
    load_dotenv()
    bot_token = os.getenv("TELEGRAM_BOT_TOKEN")
    if not bot_token:
        raise ValueError("La variabile d'ambiente TELEGRAM_BOT_TOKEN non è impostata.")

    application = Application.builder().token(bot_token).build()

    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(button_callback))

    application.run_polling()


if __name__ == "__main__":
    main()
