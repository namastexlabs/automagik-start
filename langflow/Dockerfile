FROM langflowai/langflow:latest

# Upgrade pip in the virtual environment
RUN /app/.venv/bin/python -m ensurepip --upgrade

# Install docling and related packages using the virtual environment's pip
RUN /app/.venv/bin/python -m pip install --upgrade pip && \
    /app/.venv/bin/python -m pip install \
    docling \
    docling-core \
    pypdfium2 \
    python-docx \
    python-pptx \
    openpyxl

# Set environment path to use virtual environment
ENV PATH="/app/.venv/bin:$PATH"

# Use the virtual environment's Python to run langflow
CMD ["python", "-m", "langflow", "run", "--host", "0.0.0.0", "--port", "7860"]