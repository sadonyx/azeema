const profileBtn = document.getElementById("profile-btn");
const profileDropdown = document.getElementById("profile-dropdown");

const toggleProfileDropdown = function() {
  profileDropdown.classList.toggle("profile-show");
};

profileBtn.addEventListener("click", function(e) {
  e.stopPropagation();
  toggleProfileDropdown();
});

document.documentElement.addEventListener("click", function() {
  if (profileDropdown.classList.contains("profile-show")) {
    toggleProfileDropdown();
  }
});
