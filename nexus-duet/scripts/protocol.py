import os
from dotenv import load_dotenv
from google import genai
from rich.console import Console
from rich.panel import Panel
from rich.syntax import Syntax

console = Console()

class NexusBase:
    def __init__(self, name):
        self.name = name
        # Load your specific athena.env
        env_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../athena.env"))
        load_dotenv(dotenv_path=env_path)
        
        # The 2025 SDK automatically uses the GEMINI_API_KEY env var
        # if it is set. We initialize the client here.
        self.client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

    def build_with_approval(self, explanation, code_payload, target_file):
        console.print(Panel(f"[bold cyan]AGENT: {self.name}[/]\n\n[bold green]EXPLANATION:[/]\n{explanation}", title="Action Proposed"))
        syntax = Syntax(code_payload, "bash" if target_file.endswith(".sh") else "python", theme="monokai")
        console.print(Panel(syntax, title=f"Proposed Build: {target_file}", border_style="yellow"))
        
        confirm = console.input("\n[bold yellow]APPROVE AND REBUILD? (y/n): [/]").lower().strip()
        if confirm == 'y':
            with open(target_file, "w") as f:
                f.write(code_payload)
            console.print(f"✅ [bold green]BUILD COMPLETE:[/] {target_file} updated.")
            return True
        return False
