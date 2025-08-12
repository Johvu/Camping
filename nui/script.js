const state = {
  isVisible: false,
  recipes: [],
  inventory: {},
  fuelLevel: 0,
  skill: { level: 1, xp: 0, nextLevelXP: 100 },
  expandedRecipes: {},
  activeTab: "all",
  searchQuery: "",
  sortBy: "name",
  filterBy: "all",
  favorites: JSON.parse(localStorage.getItem("campfire-favorites") || "[]"),
  cookingQueue: [],
  theme: localStorage.getItem("campfire-theme") || "dark",
  notifications: [],
  isCreatingRecipe: false,
  customRecipes: JSON.parse(localStorage.getItem("campfire-custom-recipes") || "[]"),
}

document.addEventListener("DOMContentLoaded", () => {
  // Apply saved theme
  document.body.className = `${state.theme}-theme`

  // Load saved data
  loadSavedData()

  // Listen for messages from the game client
  window.addEventListener("message", ({ data }) => {
    switch (data.action) {
      case "openCookingMenu":
        state.isVisible = true
        state.recipes = [...(data.recipes || []), ...state.customRecipes]
        state.inventory = data.inventory || {}
        state.fuelLevel = data.fuelLevel || 0
        if (data.skill) state.skill = data.skill
        break
      case "hide":
        state.isVisible = false
        break
      case "updateInventory":
        state.inventory = data.inventory || {}
        state.fuelLevel = data.fuelLevel || 0
        break
      case "updateFuel":
        state.fuelLevel = data.fuelLevel || 0
        break
      case "updateSkill":
        if (data.skill) state.skill = data.skill
        break
      case "cookingComplete":
        handleCookingComplete(data.recipeId)
        break
      default:
        break
    }
    renderUI()
  })

  setInterval(saveData, 30000) // Save every 30 seconds

  setInterval(updateCookingQueue, 1000)

  // Initial render
  renderUI()
})

function loadSavedData() {
  const savedFavorites = localStorage.getItem("campfire-favorites")
  if (savedFavorites) {
    state.favorites = JSON.parse(savedFavorites)
  }

  const savedCustomRecipes = localStorage.getItem("campfire-custom-recipes")
  if (savedCustomRecipes) {
    state.customRecipes = JSON.parse(savedCustomRecipes)
  }
}

function saveData() {
  localStorage.setItem("campfire-favorites", JSON.stringify(state.favorites))
  localStorage.setItem("campfire-custom-recipes", JSON.stringify(state.customRecipes))
  localStorage.setItem("campfire-theme", state.theme)
}

function getFilteredRecipes() {
  const filtered = state.recipes.filter((recipe) => {
    // Tab filter
    if (state.activeTab !== "all" && recipe.category !== state.activeTab) {
      return false
    }

    // Search filter
    if (state.searchQuery) {
      const query = state.searchQuery.toLowerCase()
      const matchesName = recipe.label.toLowerCase().includes(query)
      const matchesDescription = recipe.description.toLowerCase().includes(query)
      const matchesIngredients = recipe.ingredients.some((ing) => ing.name.toLowerCase().includes(query))
      if (!matchesName && !matchesDescription && !matchesIngredients) {
        return false
      }
    }

    // Additional filters
    if (state.filterBy === "favorites" && !state.favorites.includes(recipe.id)) {
      return false
    }
    if (state.filterBy === "cookable") {
      const hasAllIngredients = recipe.ingredients.every(
        (ingredient) => (state.inventory[ingredient.name] || 0) >= ingredient.count,
      )
      const requiredFuel = (recipe.cookTime / 1000) * 0.5
      const hasFuel = state.fuelLevel >= requiredFuel
      if (!hasAllIngredients || !hasFuel) {
        return false
      }
    }

    return true
  })

  // Sort recipes
  filtered.sort((a, b) => {
    switch (state.sortBy) {
      case "name":
        return a.label.localeCompare(b.label)
      case "cookTime":
        return a.cookTime - b.cookTime
      case "difficulty":
        return (a.difficulty || 1) - (b.difficulty || 1)
      default:
        return 0
    }
  })

  return filtered
}

function toggleFavorite(recipeId) {
  const index = state.favorites.indexOf(recipeId)
  if (index === -1) {
    state.favorites.push(recipeId)
    showNotification("Added to favorites!", "success")
  } else {
    state.favorites.splice(index, 1)
    showNotification("Removed from favorites", "success")
  }
  saveData()
  renderUI()
}

function toggleTheme() {
  state.theme = state.theme === "dark" ? "light" : "dark"
  document.body.className = `${state.theme}-theme`
  saveData()
  showNotification(`Switched to ${state.theme} theme`, "success")
}

function showNotification(message, type = "info", duration = 3000) {
  const notification = {
    id: Date.now(),
    message,
    type,
    timestamp: Date.now(),
  }

  state.notifications.push(notification)

  // Create notification element
  const notificationEl = document.createElement("div")
  notificationEl.className = `notification ${type}`
  notificationEl.innerHTML = `
    <div style="display: flex; align-items: center; gap: 0.5rem;">
      <i class="fas ${getNotificationIcon(type)}"></i>
      <span>${escapeHtml(message)}</span>
    </div>
  `

  document.body.appendChild(notificationEl)

  // Remove after duration
  setTimeout(() => {
    if (notificationEl.parentNode) {
      notificationEl.parentNode.removeChild(notificationEl)
    }
    state.notifications = state.notifications.filter((n) => n.id !== notification.id)
  }, duration)
}

function getNotificationIcon(type) {
  switch (type) {
    case "success":
      return "fa-check-circle"
    case "error":
      return "fa-exclamation-circle"
    case "warning":
      return "fa-exclamation-triangle"
    default:
      return "fa-info-circle"
  }
}

function addToCookingQueue(recipeId) {
  const recipe = state.recipes.find((r) => r.id === recipeId)
  if (!recipe) return

  const cookingItem = {
    id: Date.now(),
    recipeId: recipeId,
    recipeName: recipe.label,
    startTime: Date.now(),
    duration: recipe.cookTime,
    progress: 0,
  }

  state.cookingQueue.push(cookingItem)
  showNotification(`Started cooking ${recipe.label}`, "success")
  renderUI()
}

function updateCookingQueue() {
  const now = Date.now()
  let updated = false

  state.cookingQueue = state.cookingQueue.filter((item) => {
    const elapsed = now - item.startTime
    item.progress = Math.min(100, (elapsed / item.duration) * 100)

    if (elapsed >= item.duration) {
      // Cooking complete
      showNotification(`${item.recipeName} is ready!`, "success")
      handleCookingComplete(item.recipeId)
      updated = true
      return false
    }
    return true
  })

  if (updated) {
    renderUI()
  }
}

function handleCookingComplete(recipeId) {
  // Add XP and handle completion
  const recipe = state.recipes.find((r) => r.id === recipeId)
  if (recipe) {
    const xpGain = Math.floor(recipe.cookTime / 1000) * 2
    state.skill.xp += xpGain

    // Level up check
    while (state.skill.xp >= state.skill.nextLevelXP) {
      state.skill.xp -= state.skill.nextLevelXP
      state.skill.level++
      state.skill.nextLevelXP = Math.floor(state.skill.nextLevelXP * 1.2)
      showNotification(`Cooking skill level up! Now level ${state.skill.level}`, "success")
    }
  }
}

function openRecipeCreator() {
  state.isCreatingRecipe = true
  renderRecipeCreator()
}

function closeRecipeCreator() {
  state.isCreatingRecipe = false
  renderUI()
}

function createCustomRecipe(recipeData) {
  const newRecipe = {
    id: `custom_${Date.now()}`,
    label: recipeData.name,
    description: recipeData.description,
    category: recipeData.category,
    cookTime: Number.parseInt(recipeData.cookTime) * 1000,
    ingredients: recipeData.ingredients.map((ing) => ({
      name: ing.name,
      count: Number.parseInt(ing.count),
    })),
    custom: true,
    difficulty: Number.parseInt(recipeData.difficulty) || 1,
  }

  state.customRecipes.push(newRecipe)
  state.recipes.push(newRecipe)
  saveData()
  closeRecipeCreator()
  showNotification(`Created recipe: ${newRecipe.label}`, "success")
  renderUI()
}

function renderRecipeCreator() {
  const rootElement = document.getElementById("root")

  const html = `
    <div class="fuel-modal">
      <div class="recipe-creator">
        <div class="recipe-creator-header">
          <h3 class="recipe-creator-title">Create Custom Recipe</h3>
          <p class="fuel-modal-subtitle">Design your own campfire recipe</p>
        </div>
        
        <form class="recipe-creator-form" id="recipe-form">
          <div class="form-group">
            <label class="form-label">Recipe Name</label>
            <input type="text" class="form-input" name="name" required placeholder="Enter recipe name">
          </div>
          
          <div class="form-group">
            <label class="form-label">Description</label>
            <textarea class="form-input form-textarea" name="description" placeholder="Describe your recipe"></textarea>
          </div>
          
          <div class="form-group">
            <label class="form-label">Category</label>
            <select class="form-input" name="category" required>
              <option value="meat">Meat</option>
              <option value="fish">Fish</option>
              <option value="soup">Soup</option>
              <option value="other">Other</option>
            </select>
          </div>
          
          <div class="form-group">
            <label class="form-label">Cook Time (seconds)</label>
            <input type="number" class="form-input" name="cookTime" required min="1" value="30">
          </div>
          
          <div class="form-group">
            <label class="form-label">Difficulty (1-5)</label>
            <input type="number" class="form-input" name="difficulty" min="1" max="5" value="1">
          </div>
          
          <div class="form-group">
            <label class="form-label">Ingredients</label>
            <div class="ingredients-list" id="ingredients-list">
              <div class="ingredient-input">
                <input type="text" class="form-input" placeholder="Ingredient name" name="ingredient-name">
                <input type="number" class="form-input" placeholder="Count" name="ingredient-count" min="1" style="width: 80px;">
                <button type="button" onclick="removeIngredient(this)">×</button>
              </div>
            </div>
            <button type="button" class="add-ingredient-btn" onclick="addIngredientInput()">
              <i class="fas fa-plus"></i> Add Ingredient
            </button>
          </div>
          
          <div class="fuel-modal-footer">
            <button type="button" class="fuel-modal-button cancel" onclick="closeRecipeCreator()">Cancel</button>
            <button type="submit" class="fuel-modal-button add">Create Recipe</button>
          </div>
        </form>
      </div>
    </div>
  `

  rootElement.innerHTML = html

  // Add form submission handler
  document.getElementById("recipe-form").addEventListener("submit", (e) => {
    e.preventDefault()
    const formData = new FormData(e.target)

    // Collect ingredients
    const ingredientNames = formData.getAll("ingredient-name").filter((name) => name.trim())
    const ingredientCounts = formData.getAll("ingredient-count").filter((count) => count)

    const ingredients = ingredientNames.map((name, index) => ({
      name: name.trim(),
      count: Number.parseInt(ingredientCounts[index]) || 1,
    }))

    if (ingredients.length === 0) {
      showNotification("Please add at least one ingredient", "error")
      return
    }

    const recipeData = {
      name: formData.get("name"),
      description: formData.get("description"),
      category: formData.get("category"),
      cookTime: formData.get("cookTime"),
      difficulty: formData.get("difficulty"),
      ingredients: ingredients,
    }

    createCustomRecipe(recipeData)
  })
}

// Helper functions for recipe creator
function addIngredientInput() {
  const container = document.getElementById("ingredients-list")
  const div = document.createElement("div")
  div.className = "ingredient-input"
  div.innerHTML = `
    <input type="text" class="form-input" placeholder="Ingredient name" name="ingredient-name">
    <input type="number" class="form-input" placeholder="Count" name="ingredient-count" min="1" style="width: 80px;">
    <button type="button" onclick="removeIngredient(this)">×</button>
  `
  container.appendChild(div)
}

function removeIngredient(button) {
  button.parentElement.remove()
}

function renderUI() {
  const rootElement = document.getElementById("root")
  if (!rootElement) {
    return
  }

  if (!state.isVisible) {
    rootElement.innerHTML = ""
    return
  }

  if (state.isCreatingRecipe) {
    renderRecipeCreator()
    return
  }

  // Get filtered recipes
  const filteredRecipes = getFilteredRecipes()
  const fuelClass = state.fuelLevel < 20 ? "low" : ""

  // Build the HTML
  let html = `
    <div class="campfire-menu">
      <div class="menu-header">
        <div>
          <h2 class="menu-title">Campfire Cooking</h2>
          <p class="menu-subtitle">Prepare meals to restore health and gain buffs</p>
        </div>
        <div class="header-controls">
          <button class="theme-toggle" id="theme-toggle" title="Toggle theme">
            <i class="fas ${state.theme === "dark" ? "fa-sun" : "fa-moon"}"></i>
          </button>
          <button class="close-button" id="close-menu" title="Close menu">
            <i class="fas fa-times"></i>
          </button>
        </div>
      </div>

      <div class="fuel-section">
        <div class="fuel-info">
          <i class="fas fa-fire fuel-icon"></i>
          <div class="fuel-details">
            <span class="skill-label">Fuel</span>
            <div style="display: flex; align-items: center;">
              <div class="fuel-progress" title="${Math.round(state.fuelLevel)}% fuel">
                <div class="fuel-progress-bar ${fuelClass}" style="width: ${state.fuelLevel}%"></div>
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
  `

  if (state.cookingQueue.length > 0) {
    html += `
      <div class="cooking-queue">
        <h3 class="cooking-queue-title">
          <i class="fas fa-clock"></i>
          Currently Cooking
        </h3>
        <div class="cooking-queue-items">
    `

    state.cookingQueue.forEach((item) => {
      const remainingTime = Math.max(0, item.duration - (Date.now() - item.startTime))
      html += `
        <div class="cooking-item">
          <div class="cooking-item-name">${escapeHtml(item.recipeName)}</div>
          <div class="cooking-timer">${formatTime(remainingTime)}</div>
          <div class="cooking-progress">
            <div class="cooking-progress-bar" style="width: ${item.progress}%"></div>
          </div>
        </div>
      `
    })

    html += `
        </div>
      </div>
    `
  }

  html += `
    <div class="search-filter-section">
      <div class="search-container">
        <i class="fas fa-search search-icon"></i>
        <input type="text" class="search-input" id="search-input" 
               placeholder="Search recipes, ingredients..." 
               value="${escapeHtml(state.searchQuery)}">
      </div>
      <div class="filter-controls">
        <div class="filter-group">
          <span class="filter-label">Sort by:</span>
          <select class="filter-select" id="sort-select">
            <option value="name" ${state.sortBy === "name" ? "selected" : ""}>Name</option>
            <option value="cookTime" ${state.sortBy === "cookTime" ? "selected" : ""}>Cook Time</option>
            <option value="difficulty" ${state.sortBy === "difficulty" ? "selected" : ""}>Difficulty</option>
          </select>
        </div>
        <div class="filter-group">
          <span class="filter-label">Filter:</span>
          <select class="filter-select" id="filter-select">
            <option value="all" ${state.filterBy === "all" ? "selected" : ""}>All Recipes</option>
            <option value="favorites" ${state.filterBy === "favorites" ? "selected" : ""}>Favorites</option>
            <option value="cookable" ${state.filterBy === "cookable" ? "selected" : ""}>Can Cook</option>
          </select>
        </div>
        <button class="add-fuel-button" id="create-recipe" style="margin-left: auto;">
          <i class="fas fa-plus"></i> Create Recipe
        </button>
      </div>
    </div>
  `

  html += `
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

      // Is recipe favorited?
      const isFavorited = state.favorites.includes(recipe.id)

      html += `
        <div class="recipe-card" data-recipe-id="${recipe.id}">
          <button class="recipe-favorite ${isFavorited ? "active" : ""}" 
                  data-recipe-id="${recipe.id}" title="Toggle favorite">
            <i class="fas fa-heart"></i>
          </button>
          <div class="recipe-header">
            <div class="recipe-title">
              ${escapeHtml(recipe.label)}
              ${recipe.seasonal ? '<span class="recipe-badge">Seasonal</span>' : ""}
              ${recipe.custom ? '<span class="recipe-badge" style="background: linear-gradient(135deg, #4a9eff, #6bb6ff);">Custom</span>' : ""}
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
              ${
                recipe.difficulty
                  ? `
                <div class="recipe-info-item">
                  <i class="fas fa-star recipe-info-icon"></i>
                  <span>Level ${recipe.difficulty}</span>
                </div>
              `
                  : ""
              }
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
                ${escapeHtml(ingredient.name.charAt(0).toUpperCase() + ingredient.name.slice(1))}
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
        <i class="fas fa-search empty-state-icon"></i>
        <p class="empty-state-text">
          ${state.searchQuery ? "No recipes match your search" : "No recipes found in this category"}
        </p>
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
        <div class="footer-badge">
          <i class="fas fa-heart footer-badge-icon"></i>
          ${state.favorites.length} favorites
        </div>
      </div>
    </div>
  `

  // Set the HTML
  rootElement.innerHTML = html

  document.getElementById("close-menu").addEventListener("click", closeMenu)
  document.getElementById("add-fuel").addEventListener("click", openFuelMenu)
  document.getElementById("theme-toggle").addEventListener("click", toggleTheme)
  document.getElementById("create-recipe").addEventListener("click", openRecipeCreator)

  // Search functionality
  document.getElementById("search-input").addEventListener("input", function () {
    state.searchQuery = this.value
    renderUI()
  })

  // Sort and filter functionality
  document.getElementById("sort-select").addEventListener("change", function () {
    state.sortBy = this.value
    renderUI()
  })

  document.getElementById("filter-select").addEventListener("change", function () {
    state.filterBy = this.value
    renderUI()
  })

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

  // Favorite buttons
  document.querySelectorAll(".recipe-favorite").forEach((button) => {
    button.addEventListener("click", function (e) {
      e.stopPropagation()
      const recipeId = this.dataset.recipeId
      toggleFavorite(recipeId)
    })
  })

  // Cook buttons
  document.querySelectorAll(".cook-button:not([disabled])").forEach((button) => {
    button.addEventListener("click", function () {
      const recipeId = this.dataset.recipeId
      addToCookingQueue(recipeId)
      cookRecipe(recipeId)
    })
  })
}

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
}

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
            <span class="loading-spinner" id="fuel-loading" style="display: none;"></span>
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
      // Show loading state
      const loadingSpinner = document.getElementById("fuel-loading")
      const submitButton = document.getElementById("add-fuel-submit")
      loadingSpinner.style.display = "inline-block"
      submitButton.disabled = true

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
        .then((response) => {
          showNotification(`Added ${amount} ${selectedFuelType.label} to campfire`, "success")
          closeFuelModal()
        })
        .catch((error) => {
          showNotification("Failed to add fuel", "error")
          loadingSpinner.style.display = "none"
          submitButton.disabled = false
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
