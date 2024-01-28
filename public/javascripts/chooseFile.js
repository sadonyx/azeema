function chooseFile(event) {
  event = event || window.event;
    if(event.target.id != 'image-upload'){
      document.getElementById("image-upload").click();
    }
  };