const allEventsContainer = document.getElementById("events")
const offsetCount = { all: 4,
                      upcoming: 4,
                      hosting: 4,
                      attended: 4 }
const filter = { id: 'all' }

function filterEvents(buttonObj) {
  id = buttonObj.id
  const url = window.location.pathname + `/${id}/${offsetCount[id]}`

  if (filter.id != id) {
    filter.id = id
    const request = new XMLHttpRequest();
    
    request.onreadystatechange = function() {
      if (this.readyState == 4 && this.status == 200) {
        document.getElementById("events").innerHTML = this.responseText;
      }
    };

    request.open("GET", url, true)
    request.send();
  }
};

function loadOffset(e) {
  id = filter.id
  offsetCount[id] += 4
  const url = window.location.pathname + `/${id}/${offsetCount[id]}`

  const request = new XMLHttpRequest();
  
  request.onreadystatechange = function() {
    if (this.readyState == 4 && this.status == 200) {
      allEventsContainer.innerHTML = this.responseText;
    }
  };

  request.open("GET", url, true)
  request.send();
};

document.getElementById("button-group").addEventListener("click", function() {
  console.log(document.getElementsByClassName("selected-filter"))
  selected = document.getElementsByClassName("selected-filter") || null;
  if (selected[0]) {
    selected[0].classList.remove("selected-filter");
  };
  document.getElementById(filter.id).classList.add("selected-filter");
})

allEventsContainer.onscroll = function(ev) {
  let buttonExists = !!document.getElementById("load-offset")
  console.log(buttonExists)
  if (((allEventsContainer.scrollWidth - allEventsContainer.scrollLeft - 1) <= allEventsContainer.clientWidth) && !buttonExists){
    document.getElementById("all-events-partial").appendChild(createLoadButton())
    document.getElementById("load-offset").addEventListener("click", loadOffset)
  }


};

function createLoadButton() {
  let newButton = document.createElement("button")
  let content = document.createTextNode("Load More")
  
  newButton.appendChild(content)
  newButton.setAttribute("id", "load-offset")

  return newButton
}