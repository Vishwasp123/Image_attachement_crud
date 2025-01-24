# This code active admin Image CRUD implementation:- 
ActiveAdmin.register BxBlockTermsAndConditions::NewUpdate, as: 'New Updates' do
  permit_params :title, :description, images: []
  menu label: "Landing Page Copy",  parent: "Supports", priority: 6

  IMAGE_STYLE = 'max-width: 140px; max-height: 120px; object-fit: contain;'.freeze

  config.clear_action_items!

  action_item :custom_new_button, only: :index do
    link_to 'Add New Landing Page Copy', new_admin_new_update_path
  end

  controller do
    before_action :set_custom_page_title, only: [:new, :edit]

    private

    def set_custom_page_title
      @page_title = case action_name
                    when 'new'
                      'Create New Landing Page Copy'
                    when 'edit'
                      'Edit Landing Page Copy'
                    else
                      'Manage Landing Page Copy'
                    end
    end
  end

  index title: "Landing Page Copy" do
    id_column
    column :title
    column do |new_update|
      new_update&.description.html_safe
    end
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :title
      row :description do |new_update|
        new_update&.description.html_safe
      end
      row :images do |obj|
        div do
          obj.images.attachments
             .sort_by { |img| img.metadata['position'] || obj.images.attachments.index(img) }
             .each do |obj_img|
            div do
              if obj_img.blob.content_type.start_with?('image')
                image_tag url_for(obj_img.blob), style: IMAGE_STYLE
              elsif obj_img.blob.content_type.start_with?('video')
                video_tag url_for(obj_img.blob), controls: true, style: IMAGE_STYLE
              end
            end
          end
        end
      end
      row :created_at
      row :updated_at
    end
  end

  filter :id
  filter :title
  filter :description

  form do |f|
    f.inputs do
      f.input :title
      f.input :description, as: :quill_editor

      if f.object.images.attached?
        div style: 'display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 10px;' do
          f.label :current_image, "Current Images", style: 'font-size: 1.0em; font-weight: bold; color: #5E6469; width: 100%; margin-bottom: 10px;'

          f.object.images.attachments
            .sort_by { |img| img.metadata['position'] || f.object.images.attachments.index(img) }
            .each_with_index do |image, index|
            div style: "flex: 1 0 22%; max-width: 22%; text-align: center; margin-bottom: 20px; box-sizing: border-box;" do
              if image.content_type.start_with?('image')
                div do
                  link_to url_for(image), target: "_blank", rel: "noopener" do
                    image_tag url_for(image), style: IMAGE_STYLE
                  end
                end
              elsif image.content_type.start_with?('video')
                div do
                  link_to url_for(image), target: "_blank", rel: "noopener" do
                    video_tag url_for(image), controls: true, style: IMAGE_STYLE
                  end
                end
              end            

              div style: 'margin-top: 5px; font-size: 0.9em; color: #5E6469; word-wrap: break-word; overflow-wrap: anywhere; text-align: center; max-width: 100%;' do
                f.label :file_path, "File Path:", style: 'font-weight: bold; margin-right: 5px; display: block; margin-top: 5px;'
                a href: url_for(image), target: '_blank' do
                  span url_for(image.filename.to_s), style: 'color: #007BFF; text-decoration: underline; display: inline-block; word-wrap: break-word; overflow-wrap: anywhere; max-width: 100%; text-align: center; white-space: normal; overflow: hidden; text-overflow: ellipsis;'
                end
              end

              div style: "display: flex; justify-content: center; align-items: center; gap: 10px; margin-top: 10px;" do
                div do
                  link_to "Remove", remove_image_admin_new_update_path(f.object.id, image.id), 
                          method: :delete, 
                          data: { confirm: "Are you sure you want to remove this image?" }, 
                          style: 'display: block; margin-top: 10px; color: #000000; text-decoration: none; transition: color 0.3s ease;',
                          onmouseover: 'this.style.color="#FF0000";',
                          onmouseout: 'this.style.color="#000000";'
                end

                div do
                  # Replace button
                  link_to "Replace", replace_image_admin_new_update_path(f.object.id, image_id: image.id), 
                          method: :get,
                          data: { confirm: "Are you sure you want to replace this image?" },
                          style: 'display: block; margin-top: 10px; color: #000000; text-decoration: none; transition: color 0.3s ease;',
                          onmouseover: 'this.style.color="#FF0000";',
                          onmouseout: 'this.style.color="#000000";'
                end
              end
            end
          end
        end
      end
      f.input :images, as: :file, input_html: { multiple: true }
    end
    f.actions
  end


  controller do
    def update
      new_update = BxBlockTermsAndConditions::NewUpdate.find(params[:id])
      if params[:new_update][:images].present?
        new_images = params[:new_update][:images]
        current_size = new_update.images.size
  
        # Attach new images with positions starting after the current size
        new_images.each_with_index do |image, index|
          new_update.images.attach(io: image.tempfile,
                                   filename: image.original_filename,
                                   content_type: image.content_type,
                                   metadata: { position: current_size + index })
        end
      end
  
      if new_update.update(permitted_params[:new_update].except(:images))
        # Re-sort and reassign positions for all attachments
        new_update.images.attachments
                  .sort_by { |img| img.metadata['position'] || new_update.images.attachments.index(img) }
                  .each_with_index do |attachment, index|
          attachment.update!(metadata: attachment.metadata.merge(position: index))
        end
  
        redirect_to admin_new_update_path(new_update), notice: "Update was successful."
      else
        render :edit, alert: "Failed to update the new update."
      end
    end
  end

  member_action :remove_image, method: :delete do
   new_update = BxBlockTermsAndConditions::NewUpdate.find(params[:id])
   image = new_update.images.find(params[:format])
   image.purge
   redirect_to admin_new_update_path(new_update), notice: "Image has been removed successfully."
  end

  member_action :replace_image, method: [:get, :patch] do
    new_update = BxBlockTermsAndConditions::NewUpdate.find(params[:id])
    image = new_update.images.attachments.find_by(id: params[:image_id])
  
    if image.nil?
      redirect_to admin_new_update_path(new_update), alert: "Image not found or does not belong to this record."
      return
    end
  
    if request.patch?
      if params[:new_image].present?
        # Get the current position of the image being replaced
        original_position = image.metadata['position'] || new_update.images.attachments.index(image)
  
        # Remove the old image
        image.purge
  
        # Attach the new image with the same position
        new_update.images.attach(io: params[:new_image].tempfile,
                                 filename: params[:new_image].original_filename,
                                 content_type: params[:new_image].content_type,
                                 metadata: { position: original_position })
  
        # Sort all attachments by their `position` and reassign metadata
        new_update.images.attachments
                  .sort_by { |img| img.metadata['position'] || new_update.images.attachments.index(img) }
                  .each_with_index do |attachment, index|
          attachment.update!(metadata: attachment.metadata.merge(position: index))
        end
  
        redirect_to admin_new_update_path(new_update), notice: "Image has been replaced successfully."
      else
        redirect_to admin_new_update_path(new_update), alert: "Please select a new image to replace."
      end
    else
      @image_id = params[:image_id]
      render 'admin/new_updates/replace_image', layout: 'active_admin'
    end
  end     
end 