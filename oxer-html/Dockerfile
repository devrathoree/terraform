FROM python:3.8

WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
RUN apt-get update && apt-get install -y sudo
RUN useradd -m jenkins && echo "myuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER jenkins
COPY . .

# Expose port 5000
EXPOSE 5000

# Install sudo and configure it for Jenkins user

# Switch back to the Jenkins user


# Command to run the application
CMD ["python", "app.py"]
