-- Legend26

local module = {}

--------------------
-- UI Components
--------------------

local assetPrefix = "rbxassetid://"

function assetStr(str)
	return assetPrefix .. str
end

local assets = {
	container = assetStr("6019099585");
	outerFrame = assetStr("6019322437");
	innerFrame = assetStr("6019131481");
	decorations = assetStr("6019597035");
	auxBtnConnector = assetStr("6019652321");
	auxBtnBase = assetStr("6019651889");
	auxBtnMouseOver = assetStr("6020917142");
	auxBtnMouseDown = assetStr("6020917534");
	mainBtnBase = assetStr("6019185187");
	mainBtnMouseOver = assetStr("6020911881");
	mainBtnMouseDown = assetStr("6020911446");
	scrollUpBtnBase = assetStr("6047202035");
	scrollUpBtnMouseOver = assetStr("6047202810");
	scrollUpBtnMouseDown = assetStr("6047202372");
	scrollDownBtnBase = assetStr("6047217336");
	scrollDownBtnMouseOver = assetStr("6047218209");
	scrollDownBtnMouseDown = assetStr("6047217825");
}

function module:createGui(props)
	local gui = {}
	local refs = setupGui(props);
	local stopPulsingState = nil

	function gui:displayInScreenGui(screenGui)
		if refs.frame.Parent then
			return
		end

		if not _G.GateRemoteUIAssetsAlreadyLoaded then
			_G.GateRemoteUIAssetsAlreadyLoaded = true

			local preloadFrame = getPreloadImagesFrame()
			coroutine.wrap(function()
				game:GetService("ContentProvider"):PreloadAsync({preloadFrame})
				preloadFrame.Parent = screenGui
				wait(0.5)
				preloadFrame:Destroy()
				refs.frame.Parent = screenGui
			end)()
		else
			refs.frame.Parent = screenGui
		end
	end

	function gui:setTitle(title)
		refs.gateLabel.Text = title or ""
	end

	function gui:setState(state, showImportant)
		refs.stateLabel.Text = state or ""

		if stopPulsingState and not showImportant then
			stopPulsingState()
			stopPulsingState = nil
		elseif not stopPulsingState and showImportant then
			stopPulsingState = pulseLabelText(refs.stateLabel)
		end
	end

	function gui:setAddresses(addresses, callback)
		renderAddressList(refs.addressFrame, addresses, callback)
	end

	function gui:resetFilterSelection()
		refs.setLocalToggled(true)
	end

	function gui:setFilterEnabled(enabled)
		refs.setToggleEnabled(enabled)
	end

	return gui
end

function setupGui(props)
	local refs = {
		frame = nil;
		gateLabel = nil;
		stateLabel = nil;
		addressFrame = nil;
		setLocalToggled = nil;
		setToggledEnabled = nil;
	}

	local gateLabelRef = useRefContainer(refs, "gateLabel")
	local stateLabelRef = useRefContainer(refs, "stateLabel")
	local addressFrameRef = useRefContainer(refs, "addressFrame")
	local setLocalToggledRef = useRefContainer(refs, "setLocalToggled")
	local setToggleEnabledRef = useRefContainer(refs, "setToggleEnabled")

	local frame = element("ImageLabel",
	{
		Size = UDim2.new(0, 469, 0, 504);
		Position = UDim2.new(0.5, -469/2, 0.45, -504/2);
		BackgroundTransparency = 1;
		Image = assets.container;
	},
	{
		fullImageLabel(assets.outerFrame);
		fullImageLabel(assets.innerFrame);
		fullImageLabel(assets.decorations);
		toggleButtons(props, setLocalToggledRef, setToggleEnabledRef);

		textLabel(
		{
			Text = "Dial Home Device";
			Size = UDim2.new(0, 134, 0, 17);
			Position = UDim2.new(0, 167, 0, 13);
			TextSize = 16;
			TextYAlignment = Enum.TextYAlignment.Bottom;
		});

		textLabel(
		{
			Size = UDim2.new(0, 253, 0, 22);
			Position = UDim2.new(0, 51, 0, 48);
		},
		gateLabelRef);

		textLabel(
		{
			Size = UDim2.new(0, 59, 0, 14);
			Position = UDim2.new(0, 362, 0, 30);
			Text = "Status";
			TextSize = 16;
		});

		textLabel(
		{
			Size = UDim2.new(0, 83, 0, 22);
			Position = UDim2.new(0, 351, 0, 54);
		},
		stateLabelRef);

		element("Frame",
		{
			Size = UDim2.new(0, 318, 0, 378);
			Position = UDim2.new(0, 40, 0, 87);
			ClipsDescendants = true;
			Active = true;
			BackgroundTransparency = 1;
		},
		nil, addressFrameRef);

		renderBinaryDecoration();
	})

	refs.frame = frame
	return refs
end

function toggleButtons(props, setLocalToggledRef, setToggledEnabledRef)
	local auxLocalRef = useRef()
	local auxLocalTextRef = useRef()
	local auxRemoteRef = useRef()
	local auxRemoteTextRef = useRef()

	local auxLocalBtnProps = useImageBtn(auxLocalRef,
		assets.auxBtnBase, assets.auxBtnMouseOver, assets.auxBtnMouseDown)
	local auxRemoteBtnProps = useImageBtn(auxRemoteRef,
		assets.auxBtnBase, assets.auxBtnMouseOver, assets.auxBtnMouseDown)

	local setLocalToggled = function(isLocal)
		local localTransparency = isLocal and 0 or 0.5
		auxLocalRef.current.ImageTransparency = localTransparency
		auxLocalTextRef.current.TextTransparency = localTransparency

		local remoteTransparency = isLocal and 0.5 or 0
		auxRemoteRef.current.ImageTransparency = remoteTransparency
		auxRemoteTextRef.current.TextTransparency = remoteTransparency
	end

	local setToggledEnabled = function(enabled)
		auxLocalRef.current.Active = enabled
		auxRemoteRef.current.Active = enabled
		auxLocalTextRef.current.TextTransparency = enabled and 0 or 1
		auxRemoteTextRef.current.TextTransparency = enabled and 0 or 1

		if enabled then
			setLocalToggled(true)
		else
			auxLocalRef.current.Image = assets.auxBtnBase
			auxRemoteRef.current.Image = assets.auxBtnBase
			auxLocalRef.current.ImageTransparency = 0
			auxRemoteRef.current.ImageTransparency = 0
		end
	end

	local onLocalActivated = function()
		setLocalToggled(true)
		props.onLocalActivated()
	end

	local onRemoteActivated = function()
		setLocalToggled(false)
		props.onRemoteActivated()
	end

	local els = {
		-- aux btn connector
		element("ImageLabel",
		{
			Size = UDim2.new(0, 4, 0, 47);
			Position = UDim2.new(0, 360, 0, 286);
			BackgroundTransparency = 1;
			Image = assets.auxBtnConnector;
		});

		-- aux btn local
		element("ImageButton",
		{
			Size = UDim2.new(0, 73, 0, 39);
			Position = UDim2.new(0, 364, 0, 269);
			BackgroundTransparency = 1;
			Activated = onLocalActivated;
			_ = auxLocalBtnProps;
		},
		{
			textLabel(
			{
				Text = "Local";
				Size = UDim2.new(0, 65, 0, 28);
				Position = UDim2.new(0, 5, 0, 6);
			}, auxLocalTextRef);
		}, auxLocalRef);

		-- aux btn remote
		element("ImageButton",
		{
			Size = UDim2.new(0, 73, 0, 39);
			Position = UDim2.new(0, 364, 0, 312);
			BackgroundTransparency = 1;
			Activated = onRemoteActivated;
			_ = auxRemoteBtnProps;
		},{
			textLabel(
			{
				Text = "Remote";
				Size = UDim2.new(0, 65, 0, 28);
				Position = UDim2.new(0, 5, 0, 6);
			}, auxRemoteTextRef);
		}, auxRemoteRef);
	}

	setLocalToggled(true)
	setLocalToggledRef(setLocalToggled)
	setToggledEnabledRef(setToggledEnabled)

	return els
end

function getPreloadImagesFrame()
	return element("Frame",
		{
			Size = UDim2.new(0,0,0,0)
		},
		map(assets,
			function(image)
				return element("ImageLabel",
				{
					Image = image;
					Size = UDim2.new(0,0,0,0);
				})
			end
		)
	)
end

function renderBinaryDecoration()
	return textLabel(
	{
		Position = UDim2.new(0, 373, 0, 365);
		Size = UDim2.new(0, 64, 0, 111);
		Text = "0 1 0 1 1 0 1 0 0 0 1 0 1 0 1 0 1 0 1 0";
		TextWrapped = true;
	})
end

function renderAddressList(frame, addresses, callback)
	local containerRef = useRef()
	local scrollUpRef = useRef()
	local scrollDownRef = useRef()

	local scrollUpBtnProps = useImageBtn(scrollUpRef,
		assets.scrollUpBtnBase, assets.scrollUpBtnMouseOver, assets.scrollUpBtnMouseDown)
	local scrollDownBtnProps = useImageBtn(scrollDownRef,
		assets.scrollDownBtnBase, assets.scrollDownBtnMouseOver, assets.scrollDownBtnMouseDown)

	local scrollFrameDefaultY = 4

	local determineScrollBtnShowing = function()
		local container = containerRef.current
		local afterScrollUp = getScrollIncrement(container, true, scrollFrameDefaultY) ~= 0
		local afterScrollDown = getScrollIncrement(container, false, scrollFrameDefaultY) ~= 0

		scrollUpRef.current.Visible = afterScrollUp
		scrollDownRef.current.Visible = afterScrollDown
	end

	local onScroll = function(isUpward)
		local container = containerRef.current
		local change = getScrollIncrement(container, isUpward, scrollFrameDefaultY)
		container.Position = container.Position + UDim2.new(0, 0, 0, change)
		determineScrollBtnShowing()
	end

	local onScrollUp = function() onScroll(true) end
	local onScrollDown = function() onScroll(false) end

	replaceContents(frame,
	{
		element("Frame",
		{
			BackgroundColor3 = Color3.new(0, 1, 0);
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 4, 0, scrollFrameDefaultY);
			MouseWheelForward = onScrollUp;
			MouseWheelBackward = onScrollDown;
		},
		{
			renderAddressBtns(addresses, callback);
		},
		containerRef);

		element("ImageButton",
		{
			Size = UDim2.new(0, 10, 0, 51);
			Position = UDim2.new(1, -10, 0, 7);
			BackgroundTransparency = 1;
			Activated = onScrollUp;
			_ = scrollUpBtnProps;
		}, nil, scrollUpRef);

		element("ImageButton",
		{
			Size = UDim2.new(0, 10, 0, 51);
			Position = UDim2.new(1, -10, 0, 320);
			BackgroundTransparency = 1;
			Activated = onScrollDown;
			_ = scrollDownBtnProps;
		}, nil, scrollDownRef);
	})

	containerRef.current.Size = UDim2.new(1, -14, 0, getContainerSizeY(containerRef.current))
	determineScrollBtnShowing()
end

function getScrollIncrement(frame, isUpward, frameMaxY)
	local direction = isUpward and 1 or -1
	local increment = direction * 50

	local frameCurrentY = frame.Position.Y.Offset
	local frameMinY = -math.max(-frameMaxY, frame.Size.Y.Offset - frame.Parent.Size.Y.Offset + frameMaxY)
	if isUpward then
		if frameCurrentY > frameMaxY then
			return frameMaxY - frameCurrentY
		elseif frameCurrentY + increment > frameMaxY then
			return math.abs(frameCurrentY - frameMaxY)
		end
	else
		if frameCurrentY < frameMinY then
			return frameMinY - frameCurrentY
		elseif frameCurrentY + increment < frameMinY then
			return -math.abs(frameCurrentY - frameMinY)
		end
	end
	return increment
end

function renderAddressBtns(addresses, callback)
	local buttonYSize = 53
	local buttonYPadding = 5
	local lastPosY = 0

	return map(addresses, function(v)
		local btnRef = useRef()
		local btnProps = useImageBtn(btnRef,
			assets.mainBtnBase, assets.mainBtnMouseOver, assets.mainBtnMouseDown)

		local posY = lastPosY
		lastPosY = lastPosY + buttonYSize + buttonYPadding

		return element("ImageButton",
		{
			BackgroundTransparency = 1;
			Activated = function() callback(v.address) end;
			Size = UDim2.new(0, 296, 0, buttonYSize);
			Position = UDim2.new(0, 0, 0, posY);
			_ = btnProps;
		},
		{
			textLabel(
			{
				Size = UDim2.new(0, 211, 0, 17);
				Position = UDim2.new(0, 64, 0, 2);
				Text = v.name;
				TextXAlignment = Enum.TextXAlignment.Left;
			});
			renderAddressPieces(v.address);
		},
		btnRef)
	end)
end

function renderAddressPieces(addr)
	local els = {}

	for i,v in pairs(addr) do
		if i < 0 or i > 9 then
			break
		end

		local el = textLabel(
		{
			Size = UDim2.new(0, 28, 0, 27);
			Position = UDim2.new(0, 6 + ((i - 1) * (28 + 4)), 0, 21);
			Text = tostring(v);
		})

		table.insert(els, el)
	end

	return els
end

function fullImageLabel(image)
	return element("ImageLabel",
	{
		Size = UDim2.new(1, 0, 1, 0);
		BackgroundTransparency = 1;
		Image = image;
	});
end

function textLabel(props, ref)
	return element("TextLabel",
		apply(props, {
			BackgroundTransparency = 1;
			TextColor3 = Color3.new(1, 1, 1);
			TextTruncate = Enum.TextTruncate.AtEnd;
			TextSize = 18;
			Font = Enum.Font.ArialBold;
		}),
		nil, ref)
end

function useImageBtn(ref, mainAsset, mouseOverAsset, mouseDownAsset)
	local updateImage = function(image)
		if ref.current.Active then
			ref.current.Image = image
		else
			ref.current.Image = mainAsset
		end
	end

	return {
		Image = mainAsset;
		MouseEnter = function() updateImage(mouseOverAsset) end;
		MouseLeave = function() updateImage(mainAsset) end;
		MouseButton1Down = function() updateImage(mouseDownAsset) end;
		MouseButton1Up = function() updateImage(mouseOverAsset) end;
		Modal = true;
	}
end

function getContainerSizeY(frame)
	return reduce(
		frame:GetChildren(),
		function(maxY, child)
			return
				child:IsA "GuiObject" and
				math.max(child.Position.Y.Offset + child.Size.Y.Offset, maxY) or
				maxY
		end,
		0
	)
end

function pulseLabelText(label)
	local white = Color3.new(1, 1, 1)
	local red = Color3.new(1, 0, 0)
	local go = true

	coroutine.wrap(function()
		local towardsRed = true
		local max = 15

		while go do
			for i = 1, max do
				if not go or not label.Parent then break end
				local lerpDistance = towardsRed and i/max or (max-i)/max
				label.TextColor3 = white:Lerp(red, lerpDistance)
				wait()
			end
			towardsRed = not towardsRed
		end
	end)()

	return function()
		go = false
		label.TextColor3 = white
	end
end

--------------------
-- UI Builders
--------------------

function replaceContents(object, children)
	object:ClearAllChildren()
	forEach(children, function(v) v.Parent = object end)
end

function useRefContainer(tbl, prop)
	local refFn = function(el)
		tbl[prop] = el
	end

	return refFn
end

function useRef()
	return { current = nil }
end

function element(className, props, children, ref)
	local object = Instance.new(className)

	applyProp(object, props or {})

	for _,v in pairs(children or {}) do
		if type(v) == "table" then
			for _,k in pairs(v) do
				k.Parent = object
			end
		else
			v.Parent = object
		end
	end

	if ref then
		if type(ref) == "table" then
			ref.current = object
		else
			ref(object)
		end
	end

	return object
end

function applyProp(object, value, prop)
	if prop == nil or prop == "_" then
		forEach(value,
			function(v, i) applyProp(object, v, i) end)
	elseif type(value) == "function" then
		object[prop]:Connect(value)
	else
		object[prop] = value
	end
end

--------------------
-- Utilities
--------------------

function apply(from, into)
	forEach(from, function(v, i) into[i] = v end)
	return into
end

function map(tbl, cb)
	local result = {}

	forEach(tbl,
		function(v, i) table.insert(result, cb(v, i)) end)

	return result
end

function reduce(arr, cb, init)
	local val = init

	forEach(arr,
		function(v, i) val = cb(val, v, i) end)

	return val
end

function forEach(tbl, cb)
	for i,v in pairs(tbl) do
		cb(v, i)
	end
end

return module