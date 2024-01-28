function reloadParticipants(e) {
  const url = window.location.pathname + "/reload-participants"
  const request = new XMLHttpRequest();
  
  request.onreadystatechange = function() {
    if (this.readyState == 4 && this.status == 200) {
      document.getElementById("participants").innerHTML = this.responseText;
      document.querySelector('#participants').classList.remove("blur")
    }
  };

  request.open("GET", url, true)
  request.send();
}