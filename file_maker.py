import sys
import os

# 1. Setup the filename
filename = input("Name of file to create (e.g., story.txt): ")
if os.path.exists(filename):
    print(f"WARNING: '{filename}' already exists!")
    confirm = input("Overwrite? (y/n): ")
    if confirm.lower() != 'y':
        print("Cancelled.")
        sys.exit()

# 2. Get the prompt
user_prompt = input("What should be inside this file?: ")

# 3. Simulate Gemma (or call your actual model API here if you have the library)
# Since we are automating, we will create the file with the prompt for now 
# so you can feed it to the model, or use the output directly.
print(f"\nWriting to {filename}...")
print("------------------------------------------------")

# Note: In your previous setup, this script likely called the model. 
# If you need that specific logic back, we can add the 'ask_gemma' function here.
# For now, let's save the file so you can keep working.

with open(filename, "w", encoding="utf-8") as f:
    f.write(user_prompt) # Replacing this with the actual AI generation if needed

print("------------------------------------------------")
print(f"Success! File saved as: {filename}")
