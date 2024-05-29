// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import Rails from "@rails/ujs";
Rails.start();
import debounce from 'lodash/debounce';

document.addEventListener('DOMContentLoaded', () => {
  const searchInput = document.getElementById('search-input');

  if (searchInput) {
    searchInput.addEventListener('input', debounce((event) => {
      fetch('/searches', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name=csrf-token]').content
        },
        body: JSON.stringify({ query: event.target.value })
      });
    }, 300));
  }
});
