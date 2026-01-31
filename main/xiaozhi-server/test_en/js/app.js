// Main application entry point
import { checkOpusLoaded, initOpusEncoder } from './core/audio/opus-codec.js?v=0127';
import { getAudioPlayer } from './core/audio/player.js?v=0127';
import { checkMicrophoneAvailability, isHttpNonLocalhost } from './core/audio/recorder.js?v=0127';
import { initMcpTools } from './core/mcp/tools.js?v=0127';
import { uiController } from './ui/controller.js?v=0127';
import { log } from './utils/logger.js?v=0127';

// Application class
class App {
    constructor() {
        this.uiController = null;
        this.audioPlayer = null;
        this.live2dManager = null;
    }

    // Initialize application
    async init() {
        log('Initializing application...', 'info');
        // Initialize UI controller
        this.uiController = uiController;
        this.uiController.init();
        // Check Opus library
        checkOpusLoaded();
        // Initialize Opus encoder
        initOpusEncoder();
        // Initialize audio player
        this.audioPlayer = getAudioPlayer();
        await this.audioPlayer.start();
        // Initialize MCP tools
        initMcpTools();
        // Check microphone availability
        await this.checkMicrophoneAvailability();
        // Initialize Live2D
        await this.initLive2D();
        // Hide loading indicator
        this.setModelLoadingStatus(false);
        log('Application initialization complete', 'success');
    }

    // Initialize Live2D
    async initLive2D() {
        try {
            // Check if Live2DManager is loaded
            if (typeof window.Live2DManager === 'undefined') {
                throw new Error('Live2DManager is not loaded, please check the script loading order');
            }
            this.live2dManager = new window.Live2DManager();
            await this.live2dManager.initializeLive2D();
            // Update UI status
            const live2dStatus = document.getElementById('live2dStatus');
            if (live2dStatus) {
                live2dStatus.textContent = '● Loaded';
                live2dStatus.className = 'status loaded';
            }
            log('Live2D initialization complete', 'success');
        } catch (error) {
            log(`Live2D initialization failed: ${error.message}`, 'error');
            // Update UI status
            const live2dStatus = document.getElementById('live2dStatus');
            if (live2dStatus) {
                live2dStatus.textContent = '● Load failed';
                live2dStatus.className = 'status error';
            }
        }
    }

    // Set model loading status
    setModelLoadingStatus(isLoading) {
        const modelLoading = document.getElementById('modelLoading');
        if (modelLoading) {
            modelLoading.style.display = isLoading ? 'flex' : 'none';
        }
    }

    /**
     * Check microphone availability
     * Called during application initialization to check if the microphone is available and update the UI status
     */
    async checkMicrophoneAvailability() {
        try {
            const isAvailable = await checkMicrophoneAvailability();
            const isHttp = isHttpNonLocalhost();
            // Save availability status to global variables
            window.microphoneAvailable = isAvailable;
            window.isHttpNonLocalhost = isHttp;
            // Update UI
            if (this.uiController) {
                this.uiController.updateMicrophoneAvailability(isAvailable, isHttp);
            }
            log(`Microphone availability check complete: ${isAvailable ? 'Available' : 'Unavailable'}`, isAvailable ? 'success' : 'warning');
        } catch (error) {
            log(`Microphone availability check failed: ${error.message}`, 'error');
            // Default to unavailable
            window.microphoneAvailable = false;
            window.isHttpNonLocalhost = isHttpNonLocalhost();
            if (this.uiController) {
                this.uiController.updateMicrophoneAvailability(false, window.isHttpNonLocalhost);
            }
        }
    }
}

// Create and start the application
const app = new App();
// Expose the application instance to the global scope for access by other modules
window.chatApp = app;
document.addEventListener('DOMContentLoaded', () => {
    // Initialize the application
    app.init();
});
export default app;
