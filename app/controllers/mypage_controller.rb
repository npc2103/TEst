class MypageController < ApplicationController
  def show
    @user = current_user
    @book = Bookmark.where(user_id: @user.id)
    puts @book.inspect
  end

  def new
    @bookmark = Bookmark.new(user_id: current_user.id, shop_id: params[:shop_id], shop_name: params[:shop_name])
    if @bookmark.save
      flash[:notice] = "ブックマークが正常に登録されました。"
      redirect_to searches_path(latitude: params[:latitude], longitude: params[:longitude], distance: params[:distance], scroll_position: params[:scroll_position])
    else
      flash[:alert] = "ブックマークの登録に失敗しました。"
      redirect_to searches_path(latitude: params[:latitude], longitude: params[:longitude], distance: params[:distance], scroll_position: params[:scroll_position])
    end
  end

  def destroy
    @bookmark = Bookmark.find(params[:bookmark]) # パラメータ名を修正
    @bookmark.destroy
    flash[:notice] = "ブックマークが正常に削除されました。"
    redirect_to mypage_path
  end

end
