# Use a Python base image
FROM python:3.11-slim-buster

# Set timezone to Central European Time
ENV TZ=Europe/Berlin

# Set the working directory inside the container
WORKDIR /app

# Copy the project files into the container
COPY . .

# Install the project dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Command to run the job
CMD ["python", "main.py", "job"]
