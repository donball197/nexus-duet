$(document).ready(function() {
    const socket = io();
    const usernameInput = $('#username-input');
    const setUsernameBtn = $('#set-username-btn');
    const chatApp = $('#chat-app');
    const messagesDiv = $('#messages');
    
    function scrollToBottom() { messagesDiv.scrollTop(messagesDiv[0].scrollHeight); }

    function appendMessage(username, message, timestamp, isSystem = false) {
        let msgHtml = isSystem ? `<div class="message system">${message}</div>` : 
            `<div class="message"><span class="username">${username}</span>: ${message} <span class="timestamp">${timestamp}</span></div>`;
        messagesDiv.append(msgHtml);
        scrollToBottom();
    }

    setUsernameBtn.on('click', function() {
        let u = usernameInput.val().trim();
        if(u) socket.emit('set_username', {'username': u});
    });

    $('#send-button').on('click', function() {
        let m = $('#message-input').val().trim();
        if(m) { socket.emit('send_message', {'message': m}); $('#message-input').val(''); }
    });

    socket.on('username_set_success', function(data) {
        $('#username-section').addClass('hidden');
        chatApp.removeClass('hidden');
    });

    socket.on('new_message', function(data) { appendMessage(data.username, data.message, data.timestamp); });
    socket.on('user_joined', function(data) { appendMessage('System', data.username + ' joined.', '', true); });
    socket.on('user_left', function(data) { appendMessage('System', data.username + ' left.', '', true); });
    socket.on('update_user_list', function(data) {
        $('#user-list').empty();
        data.users.forEach(u => $('#user-list').append('<li>' + u + '</li>'));
    });
});
