import integrationsData from './config.js'

const currentSearchTerm = ""
let searchOverlay
let searchOverlayInput
let searchSuggestions

document.addEventListener("DOMContentLoaded", () => {
 initializeElements()
 setupEventListeners()
 renderAllIntegrations()
 renderFAQ()
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
 setupFAQ()
 window.addEventListener("scroll", updateActiveCategoryOnScroll)
}


function renderAllIntegrations() {
 renderCategoryIntegrations("Applications")
 renderCategoryIntegrations("Datastore")
}


function renderCategoryIntegrations(category) {
 const container = document.getElementById(`${category.toLowerCase()}-cards`)
 if (!container) return


 let categoryIntegrations = integrationsData.categories[category] || []


 if (currentSearchTerm) {
   categoryIntegrations = categoryIntegrations.filter(
     (integration) =>
       integration.name.toLowerCase().includes(currentSearchTerm) ||
       integration.description.toLowerCase().includes(currentSearchTerm),
   )
 }


 renderIntegrationCards(container, categoryIntegrations)
}


function renderIntegrationCards(container, integrations) {
 if (!container) return


 container.innerHTML = ""


 if (integrations.length === 0) {
   container.innerHTML = `
     <div class="no-results" role="status">
       <h3>No integrations found</h3>
       <p>Try adjusting your search criteria.</p>
     </div>
   `
   return
 }


 integrations.forEach((integration, index) => {
   const card = createIntegrationCard(integration, index)
   container.appendChild(card)
 })
}

function createIntegrationCard(integration, index) {
 const card = document.createElement("article")
 card.className = "integration-card"
 card.setAttribute("tabindex", "0")
 card.setAttribute("role", "button")
 card.setAttribute("aria-label", `${integration.name} integration. ${integration.description}`)
 card.setAttribute("data-integration-id", integration.id)
 card.setAttribute("title", integration.description)
 card.setAttribute("data-card-index", index)


card.innerHTML = `
 <a href="../src/readme.html?id=${encodeURIComponent(integration.id)}" class="integration-card-link">
   <div class="integration-card-header">
     <img
       src="${integration.icon}"
       alt=""
       class="integration-card-icon"
       aria-hidden="true"
       title="${integration.title}"
     >
     <h3 class="integration-card-title">${escapeHtml(integration.name)}</h3>
   </div>
   <p class="integration-card-description">${escapeHtml(integration.description)}</p>
 </a>
`;


 card.addEventListener("click", () => handleCardInteraction(integration))
 card.addEventListener("keydown", (e) => handleCardKeydown(e, integration, index))


 return card
}


function handleCardInteraction(integration) {
 console.log("Integration selected:", integration)
 announceToScreenReader(`Selected ${integration.name} integration`)
}


function handleCardKeydown(e, integration, index) {
 switch (e.key) {
   case "Enter":
   case " ":
     e.preventDefault()
     handleCardInteraction(integration)
     break
   case "ArrowRight":
   case "ArrowDown":
     e.preventDefault()
     focusNextCard(index)
     break
   case "ArrowLeft":
   case "ArrowUp":
     e.preventDefault()
     focusPreviousCard(index)
     break
   case "Home":
     e.preventDefault()
     focusFirstCard()
     break
   case "End":
     e.preventDefault()
     focusLastCard()
     break
 }
}


function focusNextCard(currentIndex) {
 const cards = document.querySelectorAll(".integration-card")
 const nextIndex = (currentIndex + 1) % cards.length
 cards[nextIndex]?.focus()
}


function focusPreviousCard(currentIndex) {
 const cards = document.querySelectorAll(".integration-card")
 const prevIndex = currentIndex === 0 ? cards.length - 1 : currentIndex - 1
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
 const categoryButtons = document.querySelectorAll(".category-btn");
 const category = button.getAttribute("data-category");


 categoryButtons.forEach((btn) => {
   btn.setAttribute("aria-pressed", "false");
   btn.classList.remove("active");
 });


 button.setAttribute("aria-pressed", "true");
 button.classList.add("active");


 const targetSection = document.getElementById(`${category.toLowerCase()}-section`);
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
 const categoryButtons = document.querySelectorAll(".category-btn");
 categoryButtons.forEach((btn) => {
   btn.setAttribute("aria-pressed", "false");
   btn.classList.remove("active");
 });
}


const sections = document.querySelectorAll(".category-section");
const categoryButtons = document.querySelectorAll(".category-btn");


function updateActiveCategoryOnScroll() {
 let currentActiveCategory = null;


 sections.forEach((section) => {
   const sectionTop = section.offsetTop;
   const sectionHeight = section.clientHeight;


   if (window.scrollY + 150 >= sectionTop && window.scrollY + 150 < sectionTop + sectionHeight) {
     currentActiveCategory = section.id.replace("-section", "");
   }
 });


 categoryButtons.forEach((btn) => {
   btn.setAttribute("aria-pressed", "false");
   btn.classList.remove("active");
 });


 if (currentActiveCategory) {
   const activeButton = document.querySelector(`.category-btn[data-category="${currentActiveCategory.charAt(0).toUpperCase() + currentActiveCategory.slice(1)}"]`);
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


 const allIntegrations = [
   ...integrationsData.categories.Applications,
   ...integrationsData.categories.Datastore,
 ]


 const filteredIntegrations = allIntegrations.filter(
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
   .map((integration, index) => createSearchSuggestion(integration, index))
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


function createSearchSuggestion(integration, index) {
 return `
 <a href="../src/readme.html?id=${encodeURIComponent(integration.id)}" class="integration-card-link">
   <div class="search-suggestion" tabindex="0" role="option" aria-label="${integration.name} integration">
     <img
       src="${integration.icon}"
       alt=""
       class="search-suggestion-icon"
       aria-hidden="true"
       title="${integration.description}"
     >
     <div class="search-suggestion-content">
       <div class="search-suggestion-title">${escapeHtml(integration.name)}</div>
       <div class="search-suggestion-description">${escapeHtml(integration.description)}</div>
     </div>
     <span class="search-suggestion-category">${escapeHtml(integration.category)}</span>
   </div>
 <a/>
 `
}


function handleSuggestionClick(integration) {
 closeSearchOverlay()


 const targetSection = document.getElementById(`${integration.category.toLowerCase()}-section`)
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


function setupFAQ() {
 document.addEventListener("click", (e) => {
   if (e.target.classList.contains("faq-question")) {
     handleFAQClick(e.target)
   }
 })
}


function renderFAQ() {
 const faqContainer = document.getElementById("faq-container")
 if (!faqContainer) return


 faqContainer.innerHTML = faqData.map((faq) => createFAQItem(faq)).join("")
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
 return text.replace(/[&<>"']/g, (m) => map[m])
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



