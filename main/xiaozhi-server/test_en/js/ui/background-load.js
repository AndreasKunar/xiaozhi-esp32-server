// Background image loading detection
(function() {
    const backgroundContainer = document.getElementById('backgroundContainer');

    // Extract background image URL
    let bgImageUrl = window.getComputedStyle(backgroundContainer).backgroundImage;
    const urlMatch = bgImageUrl && bgImageUrl.match(/url\(["']?(.*?)["']?\)/);
    
    if (!urlMatch || !urlMatch[1]) {
        console.warn('Failed to extract a valid background image URL');
        return;
    }
    
    bgImageUrl = urlMatch[1];
    
    const bgImage = new Image();
    bgImage.onerror = function() {
        console.error('Background image failed to load:', bgImageUrl);
    };

    // Show model loading on successful load
    bgImage.onload = function() {
        modelLoading.style.display = 'flex';
    };

    bgImage.src = bgImageUrl;
})();