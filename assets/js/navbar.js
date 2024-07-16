// https://bulma.io/documentation/components/navbar/#navbar-menu

document.addEventListener('DOMContentLoaded', () => {

    // Get all "navbar-burger" elements
    const $navbarBurgers = Array.prototype.slice.call(document.querySelectorAll('.navbar-burger'), 0);

    // Add a click event on each of them
    $navbarBurgers.forEach( el => {
      el.addEventListener('click', () => {

        // Get the target from the "data-target" attribute
        const target = el.dataset.target;
        const $target = document.getElementById(target);

        // Toggle the "is-active" class on both the "navbar-burger" and the "navbar-menu"
        el.classList.toggle('is-active');
        $target.classList.toggle('is-active');

      });
    });

    // Get all "has-dropdown" elements.
    const $hasDropdowns = Array.prototype.slice.call(document.querySelectorAll('.has-dropdown'), 0);

    // Add a click event on each of them
    $hasDropdowns.forEach( el => {
      el.addEventListener('click', () => {

        // Toggle the "is-active" class on the "has-dropdown" element
        el.classList.toggle('is-active');

      });
    });

  });
