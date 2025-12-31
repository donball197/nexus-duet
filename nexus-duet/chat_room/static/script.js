$(document).ready(function() {
    const socket = io(); // Connect to the SocketIO server

    const usernameInput = $('#username-input');
    const setUsernameBtn = $('#set-username-btn');
    const usernameError = $('#username-error');
    const usernameSection = $('#username-section');
    const chatApp = $('#chat-app');
    const messageInput = $('#message-input');
    const sendButton = $('#send-button');
    const messagesDiv = $('#messages');
    const userList = $('#user-list');

    let currentUsername = '';

    // --- Utility Functions ---
    function scrollToBottom() {
        messagesDiv.scrollTop(messagesDiv[0].scrollHeight);
    }

    function appendMessage(username, message, timestamp, isSystem = false) {
        const messageClass = isSystem ? 'system' : '';
        const messageElement = $(`<div class="message ${messageClass}"></div>`);
        if (isSystem) {
            messageElement.text(message);
        } else {
            messageElement.html(`<span class="username">${username}</span>: ${message}<span class="timestamp">${timestamp}</span>`);
        }
        messagesDiv.append(messageElement);
        scrollToBottom();
    }

    function updateUsers(users) {
        userList.empty();
        users.forEach(user => {
            userList.append($('<li>').text(user));
        });
    }

    // --- SocketIO Event Handlers ---

    // Connection events
    socket.on('connect', function() {
        console.log('Connected to server!');
    });

    socket.on('disconnect', function() {
        console.log('Disconnected from server!');
        // Optionally, show a message to the user
        appendMessage('System', 'You have been disconnected from the chat.', '', true);
        chatApp.addClass('hidden');
        usernameSection.removeClass('hidden');
        currentUsername = '';
    });

    // Username events
    setUsernameBtn.on('click', function() {
        const username = usernameInput.val().trim();
        if (username) {
            socket.emit('set_username', { 'username': username });
            usernameError.text(''); // Clear previous error
        } else {
            usernameError.text('Please enter a username.');
        }
    });

    // Allow pressing Enter in username input
    usernameInput.on('keypress', function(e) {
        if (e.which === 13) { // Enter key
            setUsernameBtn.click();
        }
    });

    socket.on('username_set_success', function(data) {
        currentUsername = data.username;
        usernameSection.addClass('hidden');
        chatApp.removeClass('hidden');
        messagesDiv.empty(); // Clear any previous messages if re-joining
        appendMessage('System', `Welcome, ${currentUsername}!`, '', true);
        messageInput.focus(); // Focus on message input
    });

    socket.on('username_error', function(data) {
        usernameError.text(data.message);
    });

    socket.on('user_joined', function(data) {
        appendMessage('System', `${data.username} has joined the chat.`, '', true);
    });

    socket.on('user_left', function(data) {
        appendMessage('System', `${data.username} has left the chat.`, '', true);
    });

    socket.on('current_users', function(data) {
        updateUsers(data.users);
    });

    socket.on('update_user_list', function(data) {
        updateUsers(data.users);
    });


    // Message events
    sendButton.on('click', function() {
        const message = messageInput.val().trim();
        if (message) {
            socket.emit('send_message', { 'message': message });
            messageInput.val(''); // Clear input
        }
    });

    // Allow pressing Enter in message input
    messageInput.on('keypress', function(e) {
        if (e.which === 13) { // Enter key
            sendButton.click();
        }
    });

    socket.on('new_message', function(data) {
        appendMessage(data.username, data.message, data.timestamp);
    });

    socket.on('message_error', function(data) {
        // This error should ideally not happen if UI enforces username first
        // But good to handle for robustness
        appendMessage('System', `Error: ${data.message}`, '', true);
    });
});

