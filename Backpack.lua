local addOnName = ...
assert(LibContainer, 'LibContainer dependency missing.')
LibContainer:SetDatabase(addOnName .. 'DB')

local LE_ITEM_QUALITY_UNCOMMON = LE_ITEM_QUALITY_UNCOMMON or Enum.ItemQuality.ItemQualityGood or 2
local LE_ITEM_CLASS_WEAPON = LE_ITEM_CLASS_WEAPON or 2
local LE_ITEM_CLASS_ARMOR = LE_ITEM_CLASS_ARMOR or 4
local LE_ITEM_CLASS_GEM = LE_ITEM_CLASS_GEM or 3
local LE_ITEM_SUBCLASS_RELIC = 11

local TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local BACKDROP = {bgFile = TEXTURE, edgeFile = TEXTURE, edgeSize = 1}

local function updateSlot(Slot)
	if(Slot:IsItemEmpty()) then
		return
	end

	local Icon = Slot.Icon
	Icon:SetTexture(Slot:GetItemIcon())
	Icon:SetDesaturated(Slot:IsItemLocked())

	local itemCount = Slot:GetItemCount()
	Slot.Count:SetText(itemCount > 1e3 and '*' or itemCount > 1 and itemCount or '')

	local itemQuality = Slot:GetItemQuality()
	local itemQualityColor = Slot:GetItemQualityColor().color
	local itemClass = Slot:GetItemClass()
	if(itemQuality >= LE_ITEM_QUALITY_UNCOMMON and (itemClass == LE_ITEM_CLASS_WEAPON or itemClass == LE_ITEM_CLASS_ARMOR or (itemClass == LE_ITEM_CLASS_GEM and Slot:GetItemSubClass() == LE_ITEM_SUBCLASS_RELIC))) then
		local ItemLevel = Slot.ItemLevel
		ItemLevel:SetText(Slot:GetCurrentItemLevel())
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

local function clearSlot(Slot)
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
	Slot:Show()
	Slot.Update = updateSlot
	Slot:On('PostUpdateVisibility', clearSlot)

	local Icon = Slot.Icon
	Icon:ClearAllPoints()
	Icon:SetPoint('TOPLEFT', 1, -1)
	Icon:SetPoint('BOTTOMRIGHT', -1, 1)
	Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	local Count = Slot.Count
	Count:ClearAllPoints()
	Count:SetPoint('BOTTOMRIGHT', 0, 2)
	Count:SetFontObject('PixelFont')
	Count:Show()

	local ItemLevel = Slot:CreateFontString('$parentItemLevel', 'ARTWORK', 'PixelFont')
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

local i = 1
local function styleContainer(Container)
	Container:SetBackdrop(BACKDROP)
	Container:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
	Container:SetBackdropBorderColor(0, 0, 0)

	Container:SetSlotSpacing(4)
	Container:SetSlotPadding(10)
	Container:SetSlotRelPoint('TOPLEFT')
	Container:SetSlotGrowDirection('RIGHT', 'DOWN')

	Container:SetMaxColumns(8)
	Container:SetSpacing(2)
	Container:SetPadding(10, 26)

	local Name = Container:CreateFontString('$parentName', 'ARTWORK', 'PixelFont')
	Name:SetPoint('TOPLEFT', 11, -10)
	Name:SetText(Container:GetLocalizedName())

	-- TEMP
	Container:ClearAllPoints()
	Container:SetPoint('BOTTOMRIGHT', UIParent, -50, (50*i))
	i=i+1
end

local Bags = LibContainer:New('bags', addOnName, UIParent)
Bags:On('PostCreateSlot', styleSlot)
Bags:On('PostCreateContainer', styleContainer)

do
	-- Free slots "slot" on inventory
	local function OnDrop(Slot)
		for bagID = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
			if(GetContainerNumFreeSlots(bagID) > 0) then
				for slotIndex = 1, GetContainerNumSlots(bagID) do
					if(not GetContainerItemInfo(bagID, slotIndex)) then
						PickupContainerItem(bagID, slotIndex)
						return
					end
				end
			end
		end
	end

	local function Update(self)
		local Slot = self:GetBag(0):GetSlot(99)
		Slot.Count:SetText(CalculateTotalNumberOfFreeBagSlots())
	end

	Bags:On('PostCreateBag', function(Bag)
		if(Bag:GetID() == BACKPACK_CONTAINER) then
			local Slot = Bag:CreateSlot(99)
			Slot:SetScript('OnMouseUp', OnDrop)
			Slot:SetScript('OnReceiveDrag', OnDrop)
			Slot:Show()
			Slot.Hide = nop

			-- fake info so it gets sorted last
			Slot.itemCount = 0
			Slot.itemQuality = 0
			Slot.itemID = 0
			Slot.itemLevel = 0

			Bags:GetContainer(1):AddSlot(Slot)
			Update(Bags)
		end
	end)

	Bags:RegisterEvent('BAG_UPDATE_DELAYED', Update)
end
