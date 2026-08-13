import { fetchIntegrations } from "./helm-index.js"
import { groupByCategory } from "./display.js"

// The grid is built from the Helm repository index, so a released chart that
// declares annotations.type shows up here on its own.
const HELM_INDEX_URL = "./index.yaml"

let integrations = []
let categoryGroups = []
let sections = []
let categoryButtons = []

let searchOverlay
let searchOverlayInput
let searchSuggestions

document.addEventListener("DOMContentLoaded", async () => {
 initializeElements()
 setupEventListeners()
 await loadIntegrations()
 setupAccessibility()
 updateActiveCategoryOnScroll()
})


function initializeElements() {
 searchOverlay = document.getElementById("search-overlay")
 searchOverlayInput = document.getElementById("search-overlay-input")
 searchSuggestions = document.getElementById("search-suggestions")
}


function setupEventListeners() {
 setupSearch()
 setupCategorySidebar()
 setupKeyboardShortcuts()
 setupSearchOverlay()
 window.addEventListener("scroll", updateActiveCategoryOnScroll)
}


async function loadIntegrations() {
 const container = document.querySelector(".integration-sections")

 try {
   integrations = await fetchIntegrations(HELM_INDEX_URL)
   categoryGroups = groupByCategory(integrations)
   integrations = categoryGroups.flatMap((group) => group.items)

   renderCategories(categoryGroups)
 } catch (error) {
   console.error("Failed to load integrations from the Helm index:", error)

   if (container) {
     container.innerHTML = `
       <div class="no-results" role="status">
         <h3>Couldn't load integrations</h3>
         <p>Please refresh the page to try again.</p>
       </div>
     `
   }
 }
}


// Sidebar entries and category sections are both generated from the categories
// discovered in the index, so a brand-new annotations.type needs no edit here.
function renderCategories(groups) {
 const sidebar = document.getElementById("category-buttons")
 const container = document.querySelector(".integration-sections")
 if (!sidebar || !container) return

 sidebar.innerHTML = ""
 container.innerHTML = ""

 if (groups.length === 0) {
   container.innerHTML = `
     <div class="no-results" role="status">
       <h3>No integrations found</h3>
       <p>No published chart declares a type annotation yet.</p>
     </div>
   `
   return
 }

 groups.forEach((group) => {
   sidebar.appendChild(createCategoryButton(group))
   container.appendChild(createCategorySection(group))
 })

 cacheCategoryElements()
}


function createCategoryButton(group) {
 const item = document.createElement("li")

 const button = document.createElement("button")
 button.className = "category-btn"
 button.setAttribute("data-category", group.label)
 button.setAttribute("data-section-id", group.sectionId)
 button.setAttribute("aria-pressed", "false")
 button.textContent = group.label

 item.appendChild(button)

 return item
}


function createCategorySection(group) {
 const section = document.createElement("section")
 section.id = group.sectionId
 section.className = "category-section"

 const title = document.createElement("h3")
 title.className = "category-title"
 title.textContent = group.label

 const cards = document.createElement("div")
 cards.className = "integration-cards"
 cards.id = `${group.sectionId.replace(/-section$/, "")}-cards`
 cards.setAttribute("role", "region")
 cards.setAttribute("aria-live", "polite")
 cards.setAttribute("aria-label", `${group.label} integration cards`)

 section.appendChild(title)
 section.appendChild(cards)

 renderIntegrationCards(cards, group.items)

 return section
}


// Re-read the generated nodes: the sidebar buttons and sections only exist once
// the index has been fetched and rendered.
function cacheCategoryElements() {
 sections = Array.from(document.querySelectorAll(".category-section"))
 categoryButtons = Array.from(document.querySelectorAll(".category-btn"))
}


function renderIntegrationCards(container, cards) {
 if (!container) return


 container.innerHTML = ""


 if (cards.length === 0) {
   container.innerHTML = `
     <div class="no-results" role="status">
       <h3>No integrations found</h3>
       <p>Try adjusting your search criteria.</p>
     </div>
   `
   return
 }


 cards.forEach((integration) => {
   const card = createIntegrationCard(integration)
   container.appendChild(card)
 })
}

function createIntegrationCard(integration) {
  const card = document.createElement("article");
  card.className = "integration-card";
  card.setAttribute("tabindex", "0");
  card.setAttribute("role", "button");
  card.setAttribute("aria-label", `${integration.name} integration. ${integration.description}`);
  card.setAttribute("data-integration-id", integration.id);
  card.setAttribute("title", integration.description);

  card.innerHTML = `
    <div class="integration-card-header">
      <img
        src="${escapeHtml(integration.icon)}"
        alt=""
        class="integration-card-icon"
        aria-hidden="true"
        title="${escapeHtml(integration.name)}"
      >
      <h3 class="integration-card-title">${escapeHtml(integration.name)}</h3>
    </div>
    <p class="integration-card-description">${escapeHtml(integration.description)}</p>
  `;

  card.addEventListener("click", () => handleCardInteraction(integration));
  card.addEventListener("keydown", (e) => handleCardKeydown(e, integration));

  return card;
}

function handleCardInteraction(integration) {
  const url = `./src/readme.html?id=${encodeURIComponent(integration.id)}`;
  window.location.href = url;
}

function handleCardKeydown(e, integration) {
  switch (e.key) {
    case "Enter":
    case " ":
      e.preventDefault();
      handleCardInteraction(integration);
      break;
    case "ArrowRight":
    case "ArrowDown":
      e.preventDefault();
      focusNextCard(currentCardIndex(e.currentTarget));
      break;
    case "ArrowLeft":
    case "ArrowUp":
      e.preventDefault();
      focusPreviousCard(currentCardIndex(e.currentTarget));
      break;
    case "Home":
      e.preventDefault();
      focusFirstCard();
      break;
    case "End":
      e.preventDefault();
      focusLastCard();
      break;
  }
}

// Arrow-key navigation walks every rendered card, so the index has to come from
// the document order rather than the card's position within its own category.
function currentCardIndex(card) {
 const cards = Array.from(document.querySelectorAll(".integration-card"))
 return cards.indexOf(card)
}

function focusNextCard(currentIndex) {
 const cards = document.querySelectorAll(".integration-card")
 if (cards.length === 0) return
 const nextIndex = (currentIndex + 1) % cards.length
 cards[nextIndex]?.focus()
}


function focusPreviousCard(currentIndex) {
 const cards = document.querySelectorAll(".integration-card")
 if (cards.length === 0) return
 const prevIndex = currentIndex <= 0 ? cards.length - 1 : currentIndex - 1
 cards[prevIndex]?.focus()
}


function focusFirstCard() {
 const firstCard = document.querySelector(".integration-card")
 firstCard?.focus()
}


function focusLastCard() {
 const cards = document.querySelectorAll(".integration-card")
 const lastCard = cards[cards.length - 1]
 lastCard?.focus()
}


function setupSearch() {
 const searchInput = document.getElementById("search-integrations")
 if (!searchInput) return


 searchInput.addEventListener("click", openSearchOverlay)
 searchInput.addEventListener("focus", openSearchOverlay)
}


function setupCategorySidebar() {
 document.addEventListener("click", (e) => {
   if (e.target.classList.contains("category-btn")) {
     handleCategoryClick(e.target)
   }
 })
}


function handleCategoryClick(button) {
 const category = button.getAttribute("data-category");
 const sectionId = button.getAttribute("data-section-id");


 clearCategoryHighlights();


 button.setAttribute("aria-pressed", "true");
 button.classList.add("active");


 const targetSection = document.getElementById(sectionId);
 if (targetSection) {
   targetSection.scrollIntoView({
     behavior: "smooth",
     block: "start",
     inline: "nearest",
   });


   announceToScreenReader(`Scrolled to ${category} section`);
 }
}


function clearCategoryHighlights() {
 document.querySelectorAll(".category-btn").forEach((btn) => {
   btn.setAttribute("aria-pressed", "false");
   btn.classList.remove("active");
 });
}


function updateActiveCategoryOnScroll() {
 let activeSectionId = null;


 sections.forEach((section) => {
   const sectionTop = section.offsetTop;
   const sectionHeight = section.clientHeight;


   if (window.scrollY + 150 >= sectionTop && window.scrollY + 150 < sectionTop + sectionHeight) {
     activeSectionId = section.id;
   }
 });


 categoryButtons.forEach((btn) => {
   btn.setAttribute("aria-pressed", "false");
   btn.classList.remove("active");
 });


 if (activeSectionId) {
   const activeButton = categoryButtons.find(
     (btn) => btn.getAttribute("data-section-id") === activeSectionId
   );
   if (activeButton) {
     activeButton.setAttribute("aria-pressed", "true");
     activeButton.classList.add("active");
   }
 }
}


document.addEventListener("click", (event) => {
 const isCategoryButton = event.target.closest(".category-btn");
 const isSearchInput = event.target.closest("#search-integrations");
 const isSearchOverlay = event.target.closest(".search-overlay-content");


 if (!isCategoryButton && !isSearchInput && !isSearchOverlay) {
   clearCategoryHighlights();
 }
});


function setupKeyboardShortcuts() {
 document.addEventListener("keydown", (e) => {
   if (e.key === "/" && !isInputFocused()) {
     e.preventDefault()
     openSearchOverlay()
   }


   if (e.key === "Escape") {
     if (searchOverlay && searchOverlay.classList.contains("active")) {
       closeSearchOverlay()
     } else if (document.activeElement && document.activeElement !== document.body) {
       document.activeElement.blur()
     }
   }
 })
}


function setupSearchOverlay() {
 if (!searchOverlay || !searchOverlayInput) return


 const closeButton = document.querySelector(".search-overlay-close")
 if (closeButton) {
   closeButton.addEventListener("click", closeSearchOverlay)
 }


 searchOverlay.addEventListener("click", (e) => {
   if (e.target === searchOverlay) {
     closeSearchOverlay()
   }
 })


 searchOverlayInput.addEventListener("input", handleOverlaySearch)
 searchOverlayInput.addEventListener("keydown", handleOverlaySearchKeydown)
}


function openSearchOverlay() {
 if (!searchOverlay || !searchOverlayInput) return


 searchOverlay.classList.add("active")
 searchOverlayInput.focus()
 document.body.style.overflow = "hidden"


 showSearchSuggestions("")


 announceToScreenReader("Search overlay opened")
}


function closeSearchOverlay() {
 if (!searchOverlay) return


 searchOverlay.classList.remove("active")
 document.body.style.overflow = ""
 searchOverlayInput.value = ""


 announceToScreenReader("Search overlay closed")
}


function handleOverlaySearch(e) {
 const searchTerm = e.target.value.toLowerCase()
 showSearchSuggestions(searchTerm)
}


function handleOverlaySearchKeydown(e) {
 if (e.key === "Escape") {
   closeSearchOverlay()
 } else if (e.key === "ArrowDown") {
   e.preventDefault()
   const firstSuggestion = document.querySelector(".search-suggestion")
   if (firstSuggestion) {
     firstSuggestion.focus()
   }
 }
}


function showSearchSuggestions(searchTerm) {
 if (!searchSuggestions) return


 if (!searchTerm || searchTerm.trim() === "") {
   searchSuggestions.innerHTML = ""
   return
 }


 const filteredIntegrations = integrations.filter(
   (integration) =>
     integration.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
     integration.description.toLowerCase().includes(searchTerm.toLowerCase())
 )


 if (filteredIntegrations.length === 0) {
   searchSuggestions.innerHTML = `
     <div class="no-suggestions">
       <p>No integrations found for "${escapeHtml(searchTerm)}"</p>
     </div>
   `
   return
 }


 searchSuggestions.innerHTML = filteredIntegrations
   .map((integration) => createSearchSuggestion(integration))
   .join("")


 const suggestionElements = document.querySelectorAll(".search-suggestion")
 suggestionElements.forEach((element, index) => {
   element.addEventListener("click", () => {
     handleSuggestionClick(filteredIntegrations[index])
   })
   element.addEventListener("keydown", (e) => {
     handleSuggestionKeydown(e, index, suggestionElements.length)
   })
 })
}


function createSearchSuggestion(integration) {
 return `
 <a href="./src/readme.html?id=${encodeURIComponent(integration.id)}" class="integration-card-link">
   <div class="search-suggestion" tabindex="0" role="option" aria-label="${escapeHtml(integration.name)} integration">
     <img
       src="${escapeHtml(integration.icon)}"
       alt=""
       class="search-suggestion-icon"
       aria-hidden="true"
       title="${escapeHtml(integration.description)}"
     >
     <div class="search-suggestion-content">
       <div class="search-suggestion-title">${escapeHtml(integration.name)}</div>
       <div class="search-suggestion-description">${escapeHtml(integration.description)}</div>
     </div>
     <span class="search-suggestion-category">${escapeHtml(integration.category)}</span>
   </div>
 </a>
 `
}


function handleSuggestionClick(integration) {
 closeSearchOverlay()


 const targetSection = document.getElementById(integration.sectionId)
 if (targetSection) {
   targetSection.scrollIntoView({
     behavior: "smooth",
     block: "start",
   })


   setTimeout(() => {
     const card = document.querySelector(`[data-integration-id="${integration.id}"]`)
     if (card) {
       card.focus()
       card.style.transform = "scale(1.02)"
       setTimeout(() => {
         card.style.transform = ""
       }, 500)
     }
   }, 500)
 }


 announceToScreenReader(`Selected ${integration.name} from search results`)
}


function handleSuggestionKeydown(e, index, totalSuggestions) {
 switch (e.key) {
   case "Enter":
   case " ":
     e.preventDefault()
     e.target.click()
     break
   case "ArrowUp":
     e.preventDefault()
     if (index === 0) {
       searchOverlayInput.focus()
     } else {
       const prevSuggestion = document.querySelectorAll(".search-suggestion")[index - 1]
       prevSuggestion?.focus()
     }
     break
   case "ArrowDown":
     e.preventDefault()
     if (index < totalSuggestions - 1) {
       const nextSuggestion = document.querySelectorAll(".search-suggestion")[index + 1]
       nextSuggestion?.focus()
     }
     break
   case "Escape":
     closeSearchOverlay()
     break
 }
}


function setupAccessibility() {
 if (!document.getElementById("sr-announcements")) {
   const announcements = document.createElement("div")
   announcements.id = "sr-announcements"
   announcements.setAttribute("aria-live", "polite")
   announcements.setAttribute("aria-atomic", "true")
   announcements.className = "sr-only"
   document.body.appendChild(announcements)
 }
}


function announceToScreenReader(message) {
 const announcements = document.getElementById("sr-announcements")
 if (announcements) {
   announcements.textContent = message
   setTimeout(() => {
     announcements.textContent = ""
   }, 1000)
 }
}


function escapeHtml(text) {
 const map = {
   "&": "&amp;",
   "<": "&lt;",
   ">": "&gt;",
   '"': "&quot;",
   "'": "&#039;",
 }
 return String(text).replace(/[&<>"']/g, (m) => map[m])
}


function isInputFocused() {
 const activeElement = document.activeElement
 return (
   activeElement &&
   (activeElement.tagName === "INPUT" ||
     activeElement.tagName === "TEXTAREA" ||
     activeElement.tagName === "SELECT" ||
     activeElement.isContentEditable)
 )
}
