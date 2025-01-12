document.addEventListener('DOMContentLoaded', function() {
    var openButton = document.querySelector('.open_phone');
    var closeButton = document.querySelector('.close_phone');
    var image = document.querySelector('.phone .phone-image');

    openButton.addEventListener('click', function() {
        image.classList.add('visible');
        openButton.style.display = 'none';
        closeButton.style.display = 'block';
    });

    closeButton.addEventListener('click', function() {
        image.classList.remove('visible');
        openButton.style.display = 'block';
        closeButton.style.display = 'none';
    });
});