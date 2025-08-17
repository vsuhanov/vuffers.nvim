local logger = require("utils.logger")
local constants = require("vuffers.constants")
local ui = require("vuffers.ui")
local buffers = require("vuffers.buffers")
local window = require("vuffers.window")
local buf_utils = require("vuffers.buffers.buffer-utils")
local config = require("vuffers.config")

local M = {}

function M.create_auto_group()
  vim.api.nvim_create_augroup(constants.AUTO_CMD_GROUP, { clear = true })

  vim.api.nvim_create_autocmd("VimEnter", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function()
      logger.debug("==================== VimEnter START ====================")
      logger.debug("VimEnter triggered - initializing vuffers")

      -- Refresh buffer list with current open buffers
      logger.debug("VimEnter: refreshing buffer list")
      buffers.reload_buffers()

      -- Find and restore any existing vuffers windows
      logger.debug("VimEnter: searching for existing vuffers windows")
      local found_windows = 0
      for _, winnr in ipairs(vim.api.nvim_list_wins()) do
        if vim.w[winnr].vuffers_window then
          found_windows = found_windows + 1
          logger.debug("VimEnter: found existing vuffers window", { winnr = winnr })
          local bufnr = vim.api.nvim_win_get_buf(winnr)
          window.restore_from_session(winnr, bufnr)
        end
      end
      logger.debug("VimEnter: found " .. found_windows .. " vuffers windows")

      -- Load saved config
      logger.debug("VimEnter: loading saved config")
      config.load_saved_config()

      logger.debug("VimEnter: setting restored from session flag")
      buffers.set_is_restored_from_session(true)

      logger.debug("==================== VimEnter END ====================")
    end,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    ---@param buffer NativeBuffer
    callback = function(buffer)
      logger.debug("==================== BufEnter START ====================")
      logger.debug("BufEnter triggered", {
        buf = buffer.buf,
        file = buffer.file,
        event = buffer.event,
        match = buffer.match
      })

      if not buf_utils.is_valid_buf(buffer) then
        logger.debug("BufEnter: buffer is not valid, skipping")
        logger.debug("==================== BufEnter END ====================")
        return
      end

      logger.debug("BufEnter: buffer is valid, processing")

      -- when buffer is open on the vuffer window, open it in another window
      if window.is_open() then
        local current_win = vim.api.nvim_get_current_win()
        local vuffer_win = window.get_window_number()
        local bufnr = window.get_buffer_number()

        logger.debug("BufEnter: vuffer window is open", {
          current_win = current_win,
          vuffer_win = vuffer_win,
          bufnr = bufnr
        })

        if current_win and vuffer_win and bufnr and current_win == vuffer_win then
          logger.debug("BufEnter: opening another buffer in vuffer window")
          vim.api.nvim_win_set_buf(vuffer_win, bufnr)
          vim.api.nvim_command("wincmd l" .. "|" .. "buffer " .. buffer.buf)
        end
      end

      logger.debug("BufEnter: calling buffers.add_buffer")
      buffers.add_buffer(buffer)

      logger.debug("BufEnter: calling buffers.set_active_buf")
      buffers.set_active_buf(buffer)

      logger.debug("BufEnter: calling buffers.set_active_pinned_bufnr")
      buffers.set_active_pinned_bufnr(buffer)

      logger.debug("==================== BufEnter END ====================")
    end,
  })

  vim.api.nvim_create_autocmd("BufAdd", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      logger.debug("==================== BufAdd START ====================")
      logger.debug("BufAdd triggered", {
        buf = buffer.buf,
        file = buffer.file,
        event = buffer.event,
        match = buffer.match
      })

      if not buf_utils.is_valid_buf(buffer) then
        logger.debug("BufAdd: buffer is not valid, skipping")
        logger.debug("==================== BufAdd END ====================")
        return
      end

      logger.debug("BufAdd: buffer is valid, processing")
      logger.debug("BufAdd: calling buffers.add_buffer")
      buffers.add_buffer(buffer)

      logger.debug("==================== BufAdd END ====================")
    end,
  })

  vim.api.nvim_create_autocmd({ "BufDelete" }, {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    ---@param buffer NativeBuffer
    callback = function(buffer)
      logger.debug("==================== BufDelete START ====================")
      logger.debug("BufDelete triggered (original)", {
        buf = buffer.buf,
        file = buffer.file,
        event = buffer.event,
        match = buffer.match
      })

      -- for BufDelete, buffer.file is relative path unlike ones in other autocmd.
      buffer = {
        buf = buffer.buf,
        event = buffer.event,
        file = buffer.match, -- buffer.file is not full path
        group = buffer.group,
        id = buffer.id,
        match = buffer.match,
      }

      logger.debug("BufDelete adjusted buffer", {
        buf = buffer.buf,
        file = buffer.file,
        event = buffer.event,
        match = buffer.match
      })

      if buffers.is_pinned(buffer) then
        logger.debug("BufDelete: buffer is pinned, reopening")
        vim.cmd("edit " .. buffer.file)
        buffers.set_active_buf(buffer)
        buffers.set_active_pinned_bufnr(buffer)
        logger.debug("==================== BufDelete END ====================")
        return
      end

      logger.debug("BufDelete: removing buffer from list")
      buffers.remove_buffer({ path = buffer.file })

      logger.debug("==================== BufDelete END ====================")
    end,
  })

  vim.api.nvim_create_autocmd({ "BufModifiedSet" }, {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      logger.debug("==================== BufModifiedSet START ====================")
      logger.debug("BufModifiedSet triggered", {
        buf = buffer.buf,
        file = buffer.file,
        event = buffer.event,
        match = buffer.match
      })

      if not buf_utils.is_valid_buf(buffer) then
        logger.debug("BufModifiedSet: buffer is not valid, skipping")
        logger.debug("==================== BufModifiedSet END ====================")
        return
      end

      logger.debug("BufModifiedSet: buffer is valid, updating modified icon")
      ui.update_modified_icon(buffer)

      logger.debug("==================== BufModifiedSet END ====================")
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      logger.debug("==================== BufWritePost START ====================")
      logger.debug("BufWritePost triggered", {
        buf = buffer.buf,
        file = buffer.file,
        event = buffer.event,
        match = buffer.match
      })

      if not buf_utils.is_valid_buf(buffer) then
        logger.debug("BufWritePost: buffer is not valid, skipping")
        logger.debug("==================== BufWritePost END ====================")
        return
      end

      logger.debug("BufWritePost: buffer is valid, updating modified icon")
      ui.update_modified_icon(buffer)

      logger.debug("==================== BufWritePost END ====================")
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      logger.debug("==================== WinClosed START ====================")
      logger.debug("WinClosed triggered", {
        buf = buffer.buf,
        file = buffer.file,
        event = buffer.event,
        match = buffer.match
      })

      -- TODO: check if this is needed
      local closed_win = tonumber(buffer.match)
      local vuffer_win = window.get_window_number()

      logger.debug("WinClosed: window numbers", {
        closed_win = closed_win,
        vuffer_win = vuffer_win
      })

      if closed_win == vuffer_win then
        logger.debug("WinClosed: vuffer window was closed, cleaning up")
        window.close()
      else
        logger.debug("WinClosed: non-vuffer window closed, ignoring")
      end

      logger.debug("==================== WinClosed END ====================")
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function()
      logger.debug("==================== VimLeavePre START ====================")
      logger.debug("VimLeavePre triggered - persisting data before exit")

      logger.debug("VimLeavePre: persisting pinned buffers")
      buffers.persist_pinned_buffers()

      if buffers.is_restored_from_session() then
        logger.debug("VimLeavePre: session was restored, persisting all buffers")
        buffers.persist_buffers()
      else
        logger.debug("VimLeavePre: no session restoration detected, skipping buffer persistence")
      end

      logger.debug("VimLeavePre: persisting config")
      config.persist_config()

      logger.debug("==================== VimLeavePre END ====================")
    end,
  })

  vim.api.nvim_create_autocmd("BufFilePost", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      logger.debug("==================== BufFilePost START ====================")
      logger.debug("BufFilePost triggered", {
        buf = buffer.buf,
        file = buffer.file,
        event = buffer.event,
        match = buffer.match
      })

      if not buf_utils.is_valid_buf(buffer) then
        logger.debug("BufFilePost: buffer is not valid, skipping")
        logger.debug("==================== BufFilePost END ====================")
        return
      end

      logger.debug("BufFilePost: buffer is valid, checking for file rename")

      -- Update buffer name in the buffer list when file is renamed
      local old_path = buffer.match -- The old filename
      local new_path = buffer.file  -- The new filename

      logger.debug("BufFilePost: file paths", {
        old_path = old_path,
        new_path = new_path,
        bufnr = buffer.buf
      })

      -- First try to update existing buffer path. If buffer doesn't exist in our list,
      -- attempt to add it (this can happen with terminal buffers and other cases)
      logger.debug("BufFilePost: attempting to update buffer path")
      local updated = buffers.update_buffer_path({ bufnr = buffer.buf, new_path = new_path })
      
      if not updated then
        logger.debug("BufFilePost: buffer not found in list, attempting to add it")
        buffers.add_buffer(buffer)
        logger.debug("BufFilePost: buffer added successfully")
      else
        logger.debug("BufFilePost: buffer path updated successfully")
      end

      logger.debug("==================== BufFilePost END ====================")
    end,
  })
end

return M
