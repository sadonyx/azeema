const dropdownBtn = document.getElementById("cal-btn");
const dropdownMenu = document.getElementById("cal-dropdown");

var timeoutId;

const toggleDropdown = function() {
  dropdownMenu.classList.toggle("cal-show");
}

dropdownBtn.addEventListener("mouseenter", function(e) {
  e.stopPropagation();
  toggleDropdown();
});

dropdownBtn.addEventListener("mouseleave", function() {
  if (dropdownMenu.classList.contains("cal-show")) {
    timeoutId = setTimeout(toggleDropdown, 250)
  }
});

dropdownMenu.addEventListener("mouseenter", function(e) {
  e.stopPropagation();
  clearTimeout(timeoutId);
  dropdownMenu.classList.add("cal-show");
});

dropdownMenu.addEventListener("mouseleave", function(e) {
  clearTimeout(timeoutId);
  toggleDropdown();
});
