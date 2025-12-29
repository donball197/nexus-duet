import React, { useState } from 'react';

function App() {
  const [input, setInput] = useState('');
  const [messages, setMessages] = useState([{text: "Hello! How can Athena AI help you today?", sender: "bot"}]);

  const sendMessage = () => {
    setMessages([...messages, {text: input, sender: "user"}]);
    setInput('');
    // Future: Fetch logic to call Backend Gemini API
  };

  return (
    <div style={{ padding: '20px', maxWidth: '600px', margin: 'auto', fontFamily: 'sans-serif' }}>
      <h2>AthenaFusionX Customer Portal</h2>
      <div style={{ border: '1px solid #ccc', height: '400px', overflowY: 'scroll', padding: '10px', marginBottom: '10px' }}>
        {messages.map((m, i) => (
          <p key={i} style={{ textAlign: m.sender === 'bot' ? 'left' : 'right' }}>
            <strong>{m.sender}:</strong> {m.text}
          </p>
        ))}
      </div>
      <input value={input} onChange={(e) => setInput(e.target.value)} style={{ width: '80%' }} />
      <button onClick={sendMessage} style={{ width: '18%' }}>Send</button>
    </div>
  );
}
export default App;
