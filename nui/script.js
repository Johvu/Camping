// Global state
const state = {
  isVisible: false,
  recipes: [],
  inventory: {},
  fuelLevel: 0,
  skill: { level: 1, xp: 0, nextLevelXP: 100 },
  expandedRecipes: {},
  activeTab: "all",
}

// Initialize when DOM is loaded
document.addEventListener("DOMContentLoaded", () => {
  // Listen for messages from the game client
  window.addEventListener("message", (event) => {
    const data = event.data
    if (data.action === "openCookingMenu") {
      state.isVisible = true
      state.recipes = data.recipes || []
      state.inventory = data.inventory || {}
      state.fuelLevel = data.fuelLevel || 0
      if (data.skill) state.skill = data.skill

      renderUI()
    } else if (data.action === "hide") {
      state.isVisible = false
      renderUI()
    } else if (data.action === "updateInventory") {
      state.inventory = data.inventory || {}
      state.fuelLevel = data.fuelLevel || 0
      renderUI()
    } else if (data.action === "updateFuel") {
      state.fuelLevel = data.fuelLevel || 0
      renderUI()
    } else if (data.action === "updateSkill") {
      if (data.skill) state.skill = data.skill
      renderUI()
    }
  })

  // Initial render
  renderUI()
})

// Format time helper
function formatTime(ms) {
  const seconds = Math.floor(ms / 1000)
  if (seconds < 60) return `${seconds}s`
  const minutes = Math.floor(seconds / 60)
  const remainingSeconds = seconds % 60
  return `${minutes}m ${remainingSeconds}s`
}

// Escape HTML to prevent injection
function escapeHtml(text = "") {
  const map = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  }
  return String(text).replace(/[&<>"']/g, (m) => map[m])
}

// Render the UI
function renderUI() {
  const rootElement = document.getElementById("root")
  if (!rootElement) {
    return
  }

  if (!state.isVisible) {
    rootElement.innerHTML = ""
    return
  }

  // Filter recipes based on active tab
  const filteredRecipes = state.recipes.filter((recipe) => {
    if (state.activeTab === "all") return true
    return recipe.category === state.activeTab
  })

  // Build the HTML
  let html = `
    <div class="campfire-menu">
      <div class="menu-header">
        <div>
          <h2 class="menu-title">Campfire Cooking</h2>
          <p class="menu-subtitle">Prepare meals to restore health and gain buffs</p>
        </div>
        <button class="close-button" id="close-menu">
          <i class="fas fa-times"></i>
        </button>
      </div>

      <div class="fuel-section">
        <div class="fuel-info">
          <i class="fas fa-fire fuel-icon"></i>
          <div>
            <span class="skill-label">Fuel</span>
            <div class="flex items-center">
              <div class="fuel-progress">
                <div class="fuel-progress-bar" style="width: ${state.fuelLevel}%"></div>
              </div>
              <span class="fuel-percentage">${Math.round(state.fuelLevel)}%</span>
            </div>
          </div>
          <button class="add-fuel-button" id="add-fuel">
            <i class="fas fa-plus"></i> Add Fuel
          </button>
        </div>

        <div class="skill-section">
          <i class="fas fa-utensils skill-icon"></i>
          <div class="skill-info">
            <span class="skill-label">Cooking Skill</span>
            <div class="skill-level">
              <span>Level ${state.skill.level}</span>
              <div class="skill-progress">
                <div class="skill-progress-bar" style="width: ${(state.skill.xp / state.skill.nextLevelXP) * 100}%"></div>
              </div>
              <span class="skill-xp">
                ${state.skill.xp}/${state.skill.nextLevelXP} XP
              </span>
            </div>
          </div>
        </div>
      </div>

      <div class="tabs">
        <div class="tab ${state.activeTab === "all" ? "active" : ""}" data-tab="all">
          All Recipes
        </div>
        <div class="tab ${state.activeTab === "meat" ? "active" : ""}" data-tab="meat">
          Meat
        </div>
        <div class="tab ${state.activeTab === "fish" ? "active" : ""}" data-tab="fish">
          Fish
        </div>
        <div class="tab ${state.activeTab === "soup" ? "active" : ""}" data-tab="soup">
          Soup
        </div>
        <div class="tab ${state.activeTab === "other" ? "active" : ""}" data-tab="other">
          Other
        </div>
      </div>

      <div class="recipes-container">
  `

  if (filteredRecipes.length > 0) {
    filteredRecipes.forEach((recipe) => {
      // Check if player has all ingredients
      const hasAllIngredients = recipe.ingredients.every(
        (ingredient) => (state.inventory[ingredient.name] || 0) >= ingredient.count,
      )

      // Calculate required fuel
      const requiredFuel = (recipe.cookTime / 1000) * 0.5
      const hasFuel = state.fuelLevel >= requiredFuel

      // Is recipe expanded?
      const isExpanded = state.expandedRecipes[recipe.id] || false

      html += `
        <div class="recipe-card" data-recipe-id="${recipe.id}">
          <div class="recipe-header">
            <div class="recipe-title">
              ${escapeHtml(recipe.label)}
              ${recipe.seasonal ? '<span class="recipe-badge">Seasonal</span>' : ""}
            </div>
            <p class="recipe-description">${escapeHtml(recipe.description)}</p>
            <div class="recipe-info">
              <div class="recipe-info-item">
                <i class="fas fa-clock recipe-info-icon"></i>
                <span>${formatTime(recipe.cookTime)}</span>
              </div>
              <div class="recipe-info-item">
                <i class="fas fa-fire recipe-info-icon"></i>
                <span>${Math.round(requiredFuel)}% fuel</span>
              </div>
            </div>
          </div>
      `

      if (isExpanded) {
        html += `
          <div class="recipe-content">
            <div class="recipe-ingredients">
              <h4 class="recipe-ingredients-title">Ingredients:</h4>
        `

        recipe.ingredients.forEach((ingredient) => {
          const playerHas = state.inventory[ingredient.name] || 0
          const hasEnough = playerHas >= ingredient.count

          html += `
            <div class="ingredient-item">
              <span class="ingredient-name">
                ${escapeHtml(
                  ingredient.name.charAt(0).toUpperCase() +
                    ingredient.name.slice(1)
                )}
              </span>
              <span class="ingredient-count ${hasEnough ? "" : "missing"}">
                ${playerHas}/${ingredient.count}
              </span>
            </div>
          `
        })

        html += `
            </div>
          </div>
        `
      }

      html += `
          <div class="recipe-footer">
            <button class="toggle-details" data-recipe-id="${recipe.id}">
              ${isExpanded ? "Hide Details" : "Show Details"}
            </button>
            <button class="cook-button" data-recipe-id="${recipe.id}" ${!hasAllIngredients || !hasFuel ? "disabled" : ""}>
              ${
                !hasAllIngredients
                  ? `
                <i class="fas fa-exclamation-triangle"></i>
                Missing Ingredients
              `
                  : !hasFuel
                    ? `
                <i class="fas fa-fire"></i>
                Not Enough Fuel
              `
                    : "Cook"
              }
            </button>
          </div>
        </div>
      `
    })
  } else {
    html += `
      <div class="empty-state">
        <i class="fas fa-box empty-state-icon"></i>
        <p class="empty-state-text">No recipes found in this category</p>
      </div>
    `
  }

  html += `
      </div>

      <div class="menu-footer">
        <div class="footer-badge">
          <i class="fas fa-clock footer-badge-icon"></i>
          Faster cooking at level 3
        </div>
        <div class="footer-badge">
          <i class="fas fa-fire footer-badge-icon"></i>
          Better quality at level 5
        </div>
      </div>
    </div>
  `

  // Set the HTML
  rootElement.innerHTML = html

  // Add event listeners
  document.getElementById("close-menu").addEventListener("click", closeMenu)
  document.getElementById("add-fuel").addEventListener("click", openFuelMenu)

  // Tab switching
  document.querySelectorAll(".tab").forEach((tab) => {
    tab.addEventListener("click", function () {
      state.activeTab = this.dataset.tab
      renderUI()
    })
  })

  // Toggle recipe details
  document.querySelectorAll(".toggle-details").forEach((button) => {
    button.addEventListener("click", function () {
      const recipeId = this.dataset.recipeId
      state.expandedRecipes[recipeId] = !state.expandedRecipes[recipeId]
      renderUI()
    })
  })

  // Cook buttons
  document.querySelectorAll(".cook-button:not([disabled])").forEach((button) => {
    button.addEventListener("click", function () {
      const recipeId = this.dataset.recipeId
      cookRecipe(recipeId)
      closeMenu()
    })
  })
}

// Close menu function
function closeMenu() {
  state.isVisible = false
  fetch("https://camping/closeCookingMenu", { method: "POST" })
  renderUI()
}

// Cook recipe function
function cookRecipe(recipeId) {
  fetch("https://camping/cookRecipe", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ recipe: recipeId }),
  })
  renderUI()
}

// Open fuel menu
function openFuelMenu() {
  // Create modal HTML
  const fuelTypes = [
    { id: "garbage", label: "Garbage", icon: "fa-trash", max: 20, value: 5 },
    { id: "firewood", label: "Firewood", icon: "fa-tree", max: 10, value: 10 },
    { id: "coal", label: "Coal", icon: "fa-fire", max: 5, value: 20 },
  ]

  let selectedFuel = "firewood"
  let amount = 1

  const selectedFuelType = fuelTypes.find((fuel) => fuel.id === selectedFuel)
  const availableAmount = state.inventory[selectedFuel] || 0
  const maxAmount = Math.min(selectedFuelType?.max || 1, availableAmount)

  let modalHtml = `
    <div class="fuel-modal" id="fuel-modal">
      <div class="fuel-modal-content">
        <div class="fuel-modal-header">
          <h3 class="fuel-modal-title">Add Fuel</h3>
          <p class="fuel-modal-subtitle">Select a fuel type and amount to add to the campfire.</p>
        </div>

        <div class="fuel-options">
  `

  fuelTypes.forEach((fuel) => {
    const available = state.inventory[fuel.id] || 0
    const isDisabled = available === 0

    modalHtml += `
      <div class="fuel-option ${selectedFuel === fuel.id ? "selected" : ""} ${isDisabled ? "disabled" : ""}" 
           data-fuel-id="${fuel.id}" ${isDisabled ? "" : 'data-selectable="true"'}>
        <div class="fuel-option-radio">
          <div class="fuel-option-radio-inner"></div>
        </div>
        <div class="fuel-option-icon">
          <i class="fas ${fuel.icon}"></i>
        </div>
        <div class="fuel-option-info">
          <div class="fuel-option-name">${fuel.label}</div>
          <div class="fuel-option-description">+${fuel.value}% fuel per unit</div>
        </div>
        <div class="fuel-option-available">Available: ${available}</div>
      </div>
    `
  })

  modalHtml += `
        </div>

        <div class="fuel-amount">
          <div class="fuel-amount-label">
            <span>Amount (Max: ${maxAmount})</span>
          </div>
          <div class="fuel-amount-controls">
            <button class="fuel-amount-button" id="decrease-amount" ${amount <= 1 ? "disabled" : ""}>
              -
            </button>
            <input type="number" class="fuel-amount-input" id="fuel-amount" value="${amount}" min="1" max="${maxAmount}">
            <button class="fuel-amount-button" id="increase-amount" ${amount >= maxAmount ? "disabled" : ""}>
              +
            </button>

            <div class="fuel-amount-preview">
              <i class="fas fa-fire"></i>
              <span>+${(selectedFuelType?.value || 0) * amount}% fuel</span>
            </div>
          </div>
        </div>

        <div class="fuel-modal-footer">
          <button class="fuel-modal-button cancel" id="cancel-fuel">
            Cancel
          </button>
          <button class="fuel-modal-button add" id="add-fuel-submit" 
                  ${amount <= 0 || amount > maxAmount || availableAmount === 0 ? "disabled" : ""}>
            Add Fuel
          </button>
        </div>
      </div>
    </div>
  `

  // Add modal to the DOM
  const modalContainer = document.createElement("div")
  modalContainer.innerHTML = modalHtml
  document.body.appendChild(modalContainer)

  // Add event listeners
  document.getElementById("cancel-fuel").addEventListener("click", closeFuelModal)
  document.getElementById("fuel-modal").addEventListener("click", (e) => {
    if (e.target.id === "fuel-modal") {
      closeFuelModal()
    }
  })

  // Fuel type selection
  document.querySelectorAll('.fuel-option[data-selectable="true"]').forEach((option) => {
    option.addEventListener("click", function () {
      selectedFuel = this.dataset.fuelId
      updateFuelModal()
    })
  })

  // Amount controls
  document.getElementById("decrease-amount").addEventListener("click", () => {
    if (amount > 1) {
      amount--
      updateFuelModal()
    }
  })

  document.getElementById("increase-amount").addEventListener("click", () => {
    const selectedFuelType = fuelTypes.find((fuel) => fuel.id === selectedFuel)
    const availableAmount = state.inventory[selectedFuel] || 0
    const maxAmount = Math.min(selectedFuelType?.max || 1, availableAmount)

    if (amount < maxAmount) {
      amount++
      updateFuelModal()
    }
  })

  document.getElementById("fuel-amount").addEventListener("change", function () {
    const value = Number.parseInt(this.value)
    if (!isNaN(value)) {
      const selectedFuelType = fuelTypes.find((fuel) => fuel.id === selectedFuel)
      const availableAmount = state.inventory[selectedFuel] || 0
      const maxAmount = Math.min(selectedFuelType?.max || 1, availableAmount)

      amount = Math.min(maxAmount, Math.max(1, value))
      updateFuelModal()
    }
  })

  // Submit button
  document.getElementById("add-fuel-submit").addEventListener("click", () => {
    const selectedFuelType = fuelTypes.find((fuel) => fuel.id === selectedFuel)
    if (amount > 0) {
      // Send data in the format expected by the client
      fetch("https://camping/addFuel", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          type: selectedFuel,
          amount: amount,
          duration: selectedFuelType.value,
        }),
      })
      .then(response => {
        closeFuelModal()
      })
      .catch(error => {
        // Still close the modal but show an error
        closeFuelModal()
        // You could add a notification here
      })
    }
  })

  // Helper function to update the fuel modal
  function updateFuelModal() {
    const selectedFuelType = fuelTypes.find((fuel) => fuel.id === selectedFuel)
    const availableAmount = state.inventory[selectedFuel] || 0
    const maxAmount = Math.min(selectedFuelType?.max || 1, availableAmount)

    // Update selected fuel option
    document.querySelectorAll(".fuel-option").forEach((option) => {
      if (option.dataset.fuelId === selectedFuel) {
        option.classList.add("selected")
      } else {
        option.classList.remove("selected")
      }
    })

    // Update amount input
    const amountInput = document.getElementById("fuel-amount")
    amountInput.value = amount
    amountInput.max = maxAmount

    // Update amount buttons
    document.getElementById("decrease-amount").disabled = amount <= 1
    document.getElementById("increase-amount").disabled = amount >= maxAmount

    // Update preview
    const previewElement = document.querySelector(".fuel-amount-preview span")
    previewElement.textContent = `+${(selectedFuelType?.value || 0) * amount}% fuel`

    // Update max amount text
    document.querySelector(".fuel-amount-label span").textContent = `Amount (Max: ${maxAmount})`

    // Update submit button
    document.getElementById("add-fuel-submit").disabled = amount <= 0 || amount > maxAmount || availableAmount === 0
  }
}

// Close fuel modal
function closeFuelModal() {
  const modal = document.getElementById("fuel-modal")
  if (modal) {
    modal.parentNode.removeChild(modal)
  }
}

