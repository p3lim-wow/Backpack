local addOnName = ...
assert(LibContainer, 'LibContainer dependency missing.')
LibContainer:SetDatabase(addOnName .. 'DB')

local LE_ITEM_QUALITY_UNCOMMON = LE_ITEM_QUALITY_UNCOMMON or Enum.ItemQuality.ItemQualityGood or 2
local LE_ITEM_CLASS_WEAPON = LE_ITEM_CLASS_WEAPON or 2
local LE_ITEM_CLASS_ARMOR = LE_ITEM_CLASS_ARMOR or 4
local LE_ITEM_CLASS_GEM = LE_ITEM_CLASS_GEM or 3
local LE_ITEM_SUBCLASS_RELIC = 11

local ICONS = [[Interface\AddOns\Backpack\assets\icons.tga]]
local TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local BACKDROP = {bgFile = TEXTURE, edgeFile = TEXTURE, edgeSize = 1}

-- widget hooks
local function onAutoVendorClick(self)
	if(LibContainer:GetVariable('autoSellJunk')) then
		self:GetNormalTexture():SetVertexColor(1, 0.1, 0.1)
	else
		self:GetNormalTexture():SetVertexColor(0.3, 0.3, 0.3)
	end
end

local function onAutoDepositClick(self)
	if(LibContainer:GetVariable('autoDeposit')) then
		self:GetNormalTexture():SetVertexColor(0, 0.6, 1)
	else
		self:GetNormalTexture():SetVertexColor(0.3, 0.3, 0.3)
	end
end

local function onSearchClick(self)
	self:SetAlpha(1)
	self:SetFrameLevel(self:GetFrameLevel() + 1)
	self.Icon:Hide()

	local Search = self.Search
	Search:Show()
	Search:SetFocus()
end

local function onSearchEnter(self)
	if(not self.Search:IsShown()) then
		self:SetAlpha(0.4)
	end
end

local function onSearchLeave(self)
	if(not self.Search:IsShown()) then
		self:SetAlpha(0)
	end
end

local function onSearchEscape(self)
	local SearchZone = self.SearchZone
	if(not MouseIsOver(SearchZone)) then
		SearchZone:SetAlpha(0)
	else
		SearchZone:SetAlpha(0.4)
	end

	SearchZone:SetFrameLevel(SearchZone:GetFrameLevel() - 1)
	SearchZone.Icon:Show()
	self:Hide()
end

local function onBagSlotsToggle(self)
	local Parent = self:GetParent():GetParent()
	if(Parent.bagSlots) then
		local isShown
		for _, Slot in next, Parent.bagSlots do
			isShown = Slot:IsShown()
			break
		end

		Parent._bagSlotsShown = isShown
		Parent:GetContainer(1):UpdateSize()
	end
end

local function onBagSlotEnter(self)
	-- highlight the slots within the bag when mousing over
	local Parent = self:GetParent()
	for bagID, Bag in next, Parent:GetBags() do
		local currentBag = bagID == self:GetID()
		for _, Slot in next, Bag:GetSlots() do
			if(Slot:IsShown()) then
				if(currentBag) then
					Slot:SetAlpha(1)
				else
					Slot:SetAlpha(0.1)
				end
			end
		end
	end
end

local function onBagSlotLeave(self)
	local Parent = self:GetParent()
	for bagID, Bag in next, Parent:GetBags() do
		for _, Slot in next, Bag:GetSlots() do
			if(Slot:IsShown()) then
				Slot:SetAlpha(1)
			end
		end
	end
end

local function onReagentBankPurchaseButtonClick()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
	StaticPopup_Show('CONFIRM_BUY_REAGENTBANK_TAB')
end

-- callbacks
local function containerUpdateSize(Container)
	local Parent = Container:GetParent()
	local categoryIndex = Container:GetID()
	if(categoryIndex == 1 and Parent._bagSlotsShown) then
		-- resize to make space for bagslots
		local width, height = Container:GetSize()
		Container:SetSize(width, height + 40)
	elseif(categoryIndex == 999) then
		-- make space for and/or show/hide reagent purchase button
		if(not IsReagentBankUnlocked()) then
			local width, height = Container:GetSize()
			Container:SetSize(width, height + 40)
			Container.PurchaseReagentBankButton:Show()
		else
			Container.PurchaseReagentBankButton:Hide()
		end
	end
end

local function slotUpdate(Slot)
	SetItemButtonTexture(Slot, Slot:GetItemTexture())
	SetItemButtonCount(Slot, Slot:GetItemCount())
	SetItemButtonDesaturated(Slot, Slot:IsItemLocked())

	local itemQuality = Slot:GetItemQuality()
	local itemQualityColor = Slot:GetItemQualityColor()
	local itemClass = Slot:GetItemClass()
	if(itemQuality >= LE_ITEM_QUALITY_UNCOMMON and (itemClass == LE_ITEM_CLASS_WEAPON or itemClass == LE_ITEM_CLASS_ARMOR or (itemClass == LE_ITEM_CLASS_GEM and Slot:GetItemSubClass() == LE_ITEM_SUBCLASS_RELIC))) then
		local ItemLevel = Slot.ItemLevel
		ItemLevel:SetText(Slot:GetItemLevel())
		ItemLevel:SetTextColor(itemQualityColor:GetRGB())
		ItemLevel:Show()
	else
		Slot.ItemLevel:Hide()
	end

	if(Slot:GetItemQuestID() or Slot:IsItemQuestItem()) then
		Slot:SetBackdropBorderColor(1, 1, 0)
	elseif(itemQuality >= LE_ITEM_QUALITY_UNCOMMON) then
		Slot:SetBackdropBorderColor(itemQualityColor:GetRGB())
	else
		Slot:SetBackdropBorderColor(0, 0, 0)
	end
end

local function slotVisibility(Slot)
	if(Slot:IsItemEmpty()) then
		local Icon = Slot.Icon
		Icon:SetTexture(nil)
		Icon:SetDesaturated(false)

		Slot.Count:SetText('')
		Slot.ItemLevel:Hide()
		Slot:SetBackdropBorderColor(0, 0, 0)
	end
end

local function styleSlot(Slot)
	Slot:SetSize(32, 32)
	Slot:SetBackdrop(BACKDROP)
	Slot:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
	Slot:SetBackdropBorderColor(0, 0, 0)
	Slot.Update = slotUpdate
	Slot:On('PostUpdateVisibility', slotVisibility)

	local Icon = Slot.Icon
	Icon:ClearAllPoints()
	Icon:SetPoint('TOPLEFT', 1, -1)
	Icon:SetPoint('BOTTOMRIGHT', -1, 1)
	Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	local Count = Slot.Count
	Count:ClearAllPoints()
	Count:SetPoint('BOTTOMRIGHT', 0, 2)
	Count:SetFontObject('PixelFontNormal')
	Count:Show()

	local ItemLevel = Slot:CreateFontString('$parentItemLevel', 'ARTWORK', 'PixelFontNormal')
	ItemLevel:SetPoint('BOTTOM', 2, 2)
	ItemLevel:SetJustifyH('CENTER')
	Slot.ItemLevel = ItemLevel

	local Pushed = Slot.PushedTexture
	Pushed:ClearAllPoints()
	Pushed:SetPoint('TOPLEFT', 1, -1)
	Pushed:SetPoint('BOTTOMRIGHT', -1, 1)
	Pushed:SetColorTexture(1, 1, 1, 0.3)

	local Highlight = Slot.HighlightTexture
	Highlight:ClearAllPoints()
	Highlight:SetPoint('TOPLEFT', 1, -1)
	Highlight:SetPoint('BOTTOMRIGHT', -1, 1)
	Highlight:SetColorTexture(0, 0.6, 1, 0.3)

	Slot.NormalTexture:SetSize(0.01, 0.01)

	local QuestIcon = Slot.QuestIcon
	if(QuestIcon) then
		QuestIcon:Hide()
	end

	local Flash = Slot.Flash
	if(Flash) then
		Flash:Hide()
	end

	local BattlePay = Slot.BattlePay
	if(BattlePay) then
		BattlePay:Hide()
	end
end

local function styleBagSlot(Slot)
	styleSlot(Slot)

	local Parent = Slot:GetParent()
	Slot:HookScript('OnEnter', onBagSlotEnter)
	Slot:HookScript('OnLeave', onBagSlotLeave)

	local isBank = Parent:GetType() == 'bank'
	local yOffset = isBank and 10 or 20
	local numBags = isBank and NUM_BANKBAGSLOTS or NUM_BAG_SLOTS
	Slot:SetPoint('BOTTOMRIGHT', Parent:GetContainer(1), -(((numBags - Slot.index) * (Slot:GetWidth() + 4)) + 10), yOffset)
end

local function styleContainer(Container)
	local isBank = Container:GetParent():GetType() == 'bank'

	Container:SetBackdrop(BACKDROP)
	Container:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
	Container:SetBackdropBorderColor(0, 0, 0)

	Container:SetSlotSize(32, 32)
	Container:SetSlotSpacing(4)
	Container:SetSlotPadding(10)
	Container:SetSlotRelPoint('TOPLEFT')
	Container:SetSlotGrowDirection('RIGHT', 'DOWN')

	Container:SetMaxColumns(8)
	Container:SetSpacing(2)

	if(isBank) then
		Container:SetRelPoint('TOPLEFT')
		Container:SetGrowDirection('RIGHT', 'DOWN')
	else
		Container:SetRelPoint('BOTTOMRIGHT')
		Container:SetGrowDirection('LEFT', 'UP')
	end

	local Name = Container:CreateFontString('$parentName', 'ARTWORK', 'PixelFontNormal')
	Name:SetPoint('TOPLEFT', 11, -10)
	Name:SetText(Container:GetLocalizedName())

	local category = Container:GetName()
	if(category == 'Inventory' and not isBank) then
		local SearchZone = CreateFrame('Button', nil, Container)
		SearchZone:SetPoint('BOTTOMLEFT')
		SearchZone:SetPoint('BOTTOMRIGHT')
		SearchZone:SetHeight(20)
		SearchZone:SetAlpha(0)
		SearchZone:SetBackdrop(BACKDROP)
		SearchZone:SetBackdropColor(0, 0, 0, 0.9)
		SearchZone:SetBackdropBorderColor(0, 0, 0)
		SearchZone:RegisterForClicks('AnyUp')
		SearchZone:SetScript('OnClick', onSearchClick)
		SearchZone:SetScript('OnEnter', onSearchEnter)
		SearchZone:SetScript('OnLeave', onSearchLeave)

		local SearchZoneIcon = SearchZone:CreateTexture('$parentIcon', 'OVERLAY')
		SearchZoneIcon:SetPoint('CENTER')
		SearchZoneIcon:SetSize(16, 16)
		SearchZoneIcon:SetTexture(ICONS)
		SearchZoneIcon:SetTexCoord(0.75, 1, 0.75, 1)
		SearchZone.Icon = SearchZoneIcon

		local Search = Container:AddWidget('Search')
		Search:SetPoint('TOPLEFT', SearchZone, 25, 0)
		Search:SetPoint('BOTTOMRIGHT', SearchZone, -5, 0)
		Search:SetFontObject('PixelFontNormal')
		Search:SetAutoFocus(true)
		Search:SetFrameLevel(Search:GetFrameLevel() + 2)
		Search:HookScript('OnEscapePressed', onSearchEscape)
		Search:Hide()
		Search.SearchZone = SearchZone
		SearchZone.Search = Search

		local SearchIcon = Search:CreateTexture('$parentIcon', 'OVERLAY')
		SearchIcon:SetPoint('RIGHT', Search, 'LEFT', -4, 0)
		SearchIcon:SetSize(16, 16)
		SearchIcon:SetTexture(ICONS)
		SearchIcon:SetTexCoord(0.75, 1, 0.75, 1)

		local Money = Container:AddWidget('Money')
		Money:SetPoint('BOTTOMRIGHT', -8, 6)
		Money.Label:SetFontObject('PixelFontNormal')

		local Currencies = Container:AddWidget('Currencies')
		Currencies:SetPoint('BOTTOMLEFT', 8, 6)
		Currencies:SetSize(1, 1)

		for index, Currency in next, Currencies.buttons do
			Currency.Label:SetFontObject('PixelFontNormal')
			Currency.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

			if(index ~= 1) then
				Currency:ClearAllPoints()
				Currency:SetPoint('BOTTOMLEFT', Currencies.buttons[index - 1], 'BOTTOMRIGHT', 5, 0)
			end
		end

		Container:SetPadding(10, 0, 26, 16)
	else
		Container:SetPadding(10, 0, 26, 0)
	end

	if(category == 'Junk' and not isBank) then
		local AutoVendor = Container:AddWidget('AutoVendor')
		AutoVendor:SetPoint('TOPRIGHT', -8, -6)
		AutoVendor:SetSize(16, 16)
		AutoVendor:SetNormalTexture(ICONS)
		AutoVendor:GetNormalTexture():SetTexCoord(0, 0.25, 0, 0.25)
		AutoVendor:HookScript('OnClick', onAutoVendorClick)
		onAutoVendorClick(AutoVendor)
	elseif(category == 'New') then
		local MarkKnown = Container:AddWidget('MarkKnown')
		MarkKnown:SetPoint('TOPRIGHT', -8, -6)
		MarkKnown:SetSize(16, 16)
		MarkKnown:SetNormalTexture(ICONS)
		MarkKnown:GetNormalTexture():SetTexCoord(0.75, 1, 0, 0.25)
	elseif(category == 'ReagentBank') then
		local Deposit = Container:AddWidget('Deposit')
		Deposit:SetPoint('TOPRIGHT', -28, -6)
		Deposit:SetSize(16, 16)
		Deposit:SetNormalTexture(ICONS)
		Deposit:GetNormalTexture():SetTexCoord(0.5, 0.75, 0, 0.25)

		local AutoDeposit = Container:AddWidget('AutoDeposit')
		AutoDeposit:SetPoint('TOPRIGHT', -48, -6)
		AutoDeposit:SetSize(16, 16)
		AutoDeposit:SetNormalTexture(ICONS)
		AutoDeposit:GetNormalTexture():SetTexCoord(0.5, 0.75, 0, 0.25)
		AutoDeposit:HookScript('OnClick', onAutoDepositClick)
		onAutoDepositClick(AutoDeposit)

		local PurchaseButton = CreateFrame('Button', nil, Container)
		PurchaseButton:SetPoint('TOPLEFT', 50, -30)
		PurchaseButton:SetPoint('BOTTOMRIGHT', -50, 20)
		PurchaseButton:SetBackdrop(BACKDROP)
		PurchaseButton:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
		PurchaseButton:SetBackdropBorderColor(0, 0, 0)
		PurchaseButton:SetNormalFontObject('PixelFontNormal')
		PurchaseButton:SetText(BANKSLOTPURCHASE)
		PurchaseButton:SetScript('OnClick', onReagentBankPurchaseButtonClick)
		Container.PurchaseReagentBankButton = PurchaseButton
	end

	if(category == 'Inventory') then
		local Bags = Container:AddWidget('Bags')
		Bags:SetPoint('TOPRIGHT', -28, -6)
		Bags:SetSize(16, 16)
		Bags:SetNormalTexture(ICONS)
		Bags:GetNormalTexture():SetTexCoord(0, 0.25, 0.25, 0.5)
		Bags:HookScript('OnClick', onBagSlotsToggle)
	end

	if(category == 'Inventory' or category == 'ReagentBank') then
		local Restack = Container:AddWidget('Restack')
		Restack:SetPoint('TOPRIGHT', -8, -6)
		Restack:SetSize(16, 16)
		Restack:SetNormalTexture(ICONS)
		Restack:GetNormalTexture():SetTexCoord(0.25, 0.5, 0, 0.25)

		Container:On('PostUpdateSize', containerUpdateSize)
	end
end

local Bags = LibContainer:New('bags', addOnName .. 'Bags', UIParent)
Bags:On('PostCreateSlot', styleSlot)
Bags:On('PostCreateContainer', styleContainer)
Bags:On('PostCreateBagSlot', styleBagSlot)
Bags:SetPoint('BOTTOMRIGHT', -50, 50)
Bags:AddFreeSlot()
Bags:AddBagSlots()
Bags:OverrideToggles()

local Bank = LibContainer:New('bank', addOnName .. 'Bank', UIParent)
Bank:On('PostCreateSlot', styleSlot)
Bank:On('PostCreateContainer', styleContainer)
Bank:On('PostCreateBagSlot', styleBagSlot)
Bank:SetPoint('TOPLEFT', 50, -50)
Bank:AddFreeSlot()
Bank:AddBagSlots()
