#!/usr/bin/env python3
"""
Teste local da lógica da Lambda (sem criar recursos AWS)
"""
import os
import json

# Simular variável de ambiente
os.environ['DB_INSTANCE_IDENTIFIER'] = 'cloudfix'

# Importar a função
from lambda_function import handler

# Teste 1: Action válida
print("=== TESTE 1: Stop ===")
event_stop = {"action": "stop"}
context = {}

try:
    result = handler(event_stop, context)
    print(f"Resultado: {json.dumps(result, indent=2)}")
except Exception as e:
    print(f"Erro: {e}")

print("\n=== TESTE 2: Start ===")
event_start = {"action": "start"}

try:
    result = handler(event_start, context)
    print(f"Resultado: {json.dumps(result, indent=2)}")
except Exception as e:
    print(f"Erro: {e}")

print("\n=== TESTE 3: Action inválida ===")
event_invalid = {"action": "invalid"}

try:
    result = handler(event_invalid, context)
    print(f"Resultado: {json.dumps(result, indent=2)}")
except Exception as e:
    print(f"Erro: {e}")
