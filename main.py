from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi_limiter import FastAPILimiter
from fastapi_limiter.depends import RateLimiter
from pydantic import BaseModel
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
import openai
import os
from dotenv import load_dotenv
import logging
import redis.asyncio as redis
from typing import Optional

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)

# Initialize FastAPI app
app = FastAPI(title="Zakhar AI API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # محدود کردن به فرانت‌اند
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

# Initialize OpenAI
openai.api_key = os.getenv("OPENAI_API_KEY")

# Initialize Redis with password
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD", "your_redis_password")
redis_client = redis.from_url(
    f"redis://:{REDIS_PASSWORD}@localhost",
    encoding="utf8",
    decode_responses=True
)

# Initialize Telegram bot
TELEGRAM_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
bot = Application.builder().token(TELEGRAM_TOKEN).build()

# Initialize rate limiter
limiter = FastAPILimiter()

class ChatRequest(BaseModel):
    message: str
    user_id: str

    def validate(self) -> Optional[str]:
        if len(self.message) > 1000:
            return "پیام شما خیلی طولانی است. لطفاً آن را کوتاه‌تر کنید."
        if not self.message.strip():
            return "پیام نمی‌تواند خالی باشد."
        return None

@app.on_event("startup")
async def startup_event():
    await limiter.init(redis_client)
    await bot.initialize()
    await bot.start()
    await bot.updater.start_polling()

@app.on_event("shutdown")
async def shutdown_event():
    await limiter.close()
    await bot.stop()
    await bot.shutdown()

@app.post("/chat")
@limiter.limit("5/minute")
async def chat(request: ChatRequest):
    # Validate message
    validation_error = request.validate()
    if validation_error:
        raise HTTPException(status_code=400, detail=validation_error)

    try:
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are Zakhar AI, a helpful and friendly AI assistant. You can help with various tasks including text generation, image editing, and general questions. You are knowledgeable in multiple languages and topics."},
                {"role": "user", "content": request.message}
            ]
        )
        return {"response": response.choices[0].message.content}
    except Exception as e:
        logging.error(f"Error in chat endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail="متأسفانه در پردازش درخواست شما مشکلی پیش آمده. لطفاً دوباره تلاش کنید.")

# Telegram bot handlers
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    welcome_message = (
        "👋 سلام! من زاخار هوشمند هستم.\n\n"
        "من می‌توانم در زمینه‌های مختلف به شما کمک کنم:\n"
        "• پاسخ به سوالات\n"
        "• ویرایش تصاویر\n"
        "• گفتگو در هر موضوعی\n"
        "• پشتیبانی از زبان‌های مختلف\n\n"
        "لطفاً سوال یا درخواست خود را مطرح کنید."
    )
    await update.message.reply_text(welcome_message)

async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        # Rate limiting for Telegram messages
        user_id = str(update.effective_user.id)
        if await redis_client.get(f"telegram_rate_limit:{user_id}"):
            await update.message.reply_text("لطفاً کمی صبر کنید و دوباره تلاش کنید.")
            return

        await redis_client.setex(f"telegram_rate_limit:{user_id}", 60, "1")

        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are Zakhar AI, a helpful and friendly AI assistant. You can help with various tasks including text generation, image editing, and general questions. You are knowledgeable in multiple languages and topics."},
                {"role": "user", "content": update.message.text}
            ]
        )
        await update.message.reply_text(response.choices[0].message.content)
    except Exception as e:
        logging.error(f"Error in Telegram message handler: {str(e)}")
        await update.message.reply_text("متأسفانه در پردازش درخواست شما مشکلی پیش آمده. لطفاً دوباره تلاش کنید.")

# Add handlers
bot.add_handler(CommandHandler("start", start))
bot.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 