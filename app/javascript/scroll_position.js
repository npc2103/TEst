window.onscroll = function() {
    var scrollPosition = window.pageYOffset || document.documentElement.scrollTop;
    document.getElementById('scroll_position').value = scrollPosition;
}

window.onload = function() {
    var urlParams = new URLSearchParams(window.location.search);
    var scrollPosition = urlParams.get('scroll_position');
    if (scrollPosition) {
        window.scrollTo(0, scrollPosition);
    }
}