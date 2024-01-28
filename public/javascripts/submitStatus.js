function formSubmit(e) {
  const url = document.getElementById('attending-status').action;
  var request = new XMLHttpRequest();
  request.open('POST', url, true);

  request.onload = function() {
    console.log(request.responseText);
  }

  request.onerror = function() {
    console.log("Not submitted")
  }

  request.send(new FormData(e.target));
  e.preventDefault();
}

function attachFormSubmitEvent(formId){
  document.getElementById(formId).addEventListener("submit", formSubmit);
}

function submitStatus(radioObj){
  if(radioObj.checked){
    attachFormSubmitEvent('attending-status');
    document.getElementById("attending-status").requestSubmit();
    console.log("submitStatus")
  }
};