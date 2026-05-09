#!/bin/bash

echo "Installing dependencies..."

python -m venv venv

source venv/bin/activate

pip install --upgrade pip

pip install -r requirements.txt

echo "Setup Complete"
