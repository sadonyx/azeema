function loadPreviewImage(event) {
    var previewMob = document.getElementById('preview-mob')
    var previewDesk = document.getElementById('preview-desk')

    previewMob.src = URL.createObjectURL(event.target.files[0]);
    previewDesk.src = URL.createObjectURL(event.target.files[0]);

    previewMob.onload = function() {
      URL.revokeObjectURL(previewMob.src)
    }

    previewDesk.onload = function() {
      URL.revokeObjectURL(previewDesk.src)
    }
  };