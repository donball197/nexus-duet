import onnxruntime as ort
import numpy as np
import sys

MODEL_PATH = "models/minilm.onnx"

session = ort.InferenceSession(MODEL_PATH, providers=["CPUExecutionProvider"])

def fake_tokenize(text):
    tokens = [min(30521, ord(c)) for c in text[:128]]
    input_ids = np.array([tokens], dtype=np.int64)
    attention_mask = np.ones_like(input_ids)
    token_type_ids = np.zeros_like(input_ids)
    return {
        "input_ids": input_ids,
        "attention_mask": attention_mask,
        "token_type_ids": token_type_ids
    }

def embed(text):
    inputs = fake_tokenize(text)
    outputs = session.run(None, inputs)
    vec = outputs[0][0]
    return vec.tolist()

if __name__ == "__main__":
    q = sys.argv[1] if len(sys.argv) > 1 else "test"
    v = embed(q)
    print(len(v))
