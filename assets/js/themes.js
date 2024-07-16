document.addEventListener('DOMContentLoaded', () => {
    // Retrieve theme selection buttons from the DOM.
    const themeButtons = {
        system: document.getElementById('themeChoiceSystem'),
        light: document.getElementById('themeChoiceLight'),
        dark: document.getElementById('themeChoiceDark'),
        oled: document.getElementById('themeChoiceOled')
    };

    // Retrieve the cookie notice elements from the DOM.
    const cookieNotice = document.getElementById('cookie-notice');
    const cookieAcceptButton = document.querySelector('.cookie-accept');
    const cookieRejectButtons = document.querySelectorAll('.cookie-reject');

    // Function to set a cookie with a name, value, and expiration in days.
    function setCookie(name, value, days) {
        const date = new Date();
        date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
        const expires = "expires=" + date.toUTCString();
        document.cookie = name + "=" + value + ";" + expires + ";path=/";
    }

    // Function to get the value of a cookie by name.
    function getCookie(name) {
        const nameEQ = name + "=";
        const ca = document.cookie.split(';');
        for (let i = 0; i < ca.length; i++) {
            let c = ca[i];
            while (c.charAt(0) == ' ') c = c.substring(1, c.length);
            if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length, c.length);
        }
        return null;
    }

    // Function to set the theme and update the selected button and cookies.
    function setTheme(theme) {
        if (theme === 'system') {
            document.documentElement.removeAttribute('data-theme');
        } else {
            document.documentElement.setAttribute('data-theme', theme);
        }
        updateSelectedButton(theme);

        // Show cookie notice if cookie consent is not given.
        if (!getCookie('cookie-consent')) {
            cookieNotice.classList.remove("is-hidden");
        } else {
            setCookie('data-theme', theme, 365);
        }
    }

    // Function to update the selected theme button's appearance.
    function updateSelectedButton(theme) {
        Object.keys(themeButtons).forEach(key => {
            themeButtons[key].classList.remove('is-selected');
        });
        themeButtons[theme].classList.add('is-selected');
    }

    // Function to handle cookie consent acceptance.
    function handleCookieConsent() {
        cookieNotice.classList.add("is-hidden");
        setCookie('cookie-consent', 'true', 365);
        setCookie('data-theme', document.documentElement.getAttribute('data-theme') || 'system', 365);
    }

    // Function to handle cookie consent rejection.
    function handleCookieRejection() {
        cookieNotice.classList.add("is-hidden");
    }

    // Event listeners for theme selection buttons.
    themeButtons.system.addEventListener('click', () => setTheme('system'));
    themeButtons.light.addEventListener('click', () => setTheme('light'));
    themeButtons.dark.addEventListener('click', () => setTheme('dark'));
    themeButtons.oled.addEventListener('click', () => setTheme('oled'));

    // Event listeners for cookie consent buttons.
    cookieAcceptButton.addEventListener('click', handleCookieConsent);
    cookieRejectButtons.forEach(button => button.addEventListener('click', handleCookieRejection));

    // Set initial theme based on saved cookie value.
    const savedTheme = getCookie('data-theme');
    if (savedTheme) {
        setTheme(savedTheme);
    }
});
