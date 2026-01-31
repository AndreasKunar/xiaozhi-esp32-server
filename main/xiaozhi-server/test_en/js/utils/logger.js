// Logging function
export function log(message, type = 'info') {
    // Split the message into multiple lines by newline character
    const lines = message.split('\n');
    const now = new Date();
    // const timestamp = `[${now.toLocaleTimeString()}] `;
    const timestamp = `[${now.toLocaleTimeString()}.${now.getMilliseconds().toString().padStart(3, '0')}] `;

    // Check if the log container exists
    const logContainer = document.getElementById('logContainer');
    if (!logContainer) {
        // If the log container does not exist, output only to the console
        console.log(`[${type.toUpperCase()}] ${message}`);
        return;
    }

    // Create log entries for each line
    lines.forEach((line, index) => {
        const logEntry = document.createElement('div');
        logEntry.className = `log-entry log-${type}`;
        // If it is the first log, display the timestamp
        const prefix = index === 0 ? timestamp : ' '.repeat(timestamp.length);
        logEntry.textContent = `${prefix}${line}`;
        // logEntry.textContent = `[${new Date().toLocaleTimeString()}] ${message}`;
        // logEntry.style preserve leading spaces
        logEntry.style.whiteSpace = 'pre';
        if (type === 'error') {
            logEntry.style.color = 'red';
        } else if (type === 'debug') {
            logEntry.style.color = 'gray';
            return;
        } else if (type === 'warning') {
            logEntry.style.color = 'orange';
        } else if (type === 'success') {
            logEntry.style.color = 'green';
        } else {
            logEntry.style.color = 'black';
        }
        logContainer.appendChild(logEntry);
    });

    logContainer.scrollTop = logContainer.scrollHeight;
}