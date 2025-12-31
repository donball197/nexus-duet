import sys
from agents.technician_local import Technician
from agents.strategist_gemini import Strategist
from rich.console import Console

console = Console()

def main():
    if len(sys.argv) < 2:
        console.print("[bold red]Usage: python3 athena_master.py \"[ISSUE]\"[/]")
        return
    
    task = sys.argv[1]

    # STEP 1: Attempt Local Fix (Technician)
    agent = Technician("Nexus-Technician")
    # propose_fix returns True if built, False if user chooses 'n'
    built_locally = agent.propose_fix(task)

    # STEP 2: Cloud Escalation if Local is rejected
    if not built_locally:
        console.print("\n🚀 [bold magenta]Escalating to Gemini Strategist (Cloud Fallback)...[/]")
        brain = Strategist("Gemini-Strategist")
        explanation, code = brain.get_strategy(task)
        
        if explanation != "FAILED":
            # Forces the same Explain -> Approve -> Build protocol
            brain.build_with_approval("Gemini Cloud Strategy generated.", explanation, "nexus_strategy_fix.sh")
        else:
            console.print("[bold red]🚨 All AI Tiers failed.[/]")

if __name__ == "__main__":
    main()
