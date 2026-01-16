async function executeAction(cmd, btn) {
    btn.innerText = "EXECUTING...";
    btn.style.background = "#444";
    
    // We send the command back to a new /execute route on our Rust backend
    const res = await fetch('/execute', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ cmd: cmd })
    });
    
    if (res.ok) {
        btn.innerText = "SUCCESS";
        btn.style.background = "#005500";
    } else {
        btn.innerText = "FAILED";
        btn.style.background = "#550000";
    }
}
