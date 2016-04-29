// AlbumsVC.swift
// Copyright (c) 2016 Nyx0uf ( https://mpdremote.whine.io )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import UIKit


final class AlbumsVC : UITableViewController
{
	// MARK: - Private properties
	// Selected artist
	private let artist: Artist
	// Label in the navigationbar
	private var titleView: UILabel! = nil
	// Keep track of download operations to eventually cancel them
	private var _downloadOperations = [String : NSOperation]()

	// MARK: - Initializers
	init(artist: Artist)
	{
		self.artist = artist
		super.init(nibName:nil, bundle:nil)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()
		self.automaticallyAdjustsScrollViewInsets = false
		// Remove back button label
		self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)

		// Tableview
		self.tableView.registerClass(AlbumTableViewCell.classForCoder(), forCellReuseIdentifier:"io.whine.mpdremote.cell.album")
		self.tableView.backgroundColor = UIColor.fromRGB(0xECECEC)
		self.tableView.separatorStyle = .None
		self.tableView.tableFooterView = UIView()

		// Navigation bar title
		self.titleView = UILabel(frame:CGRect(CGPointZero, 100.0, 44.0))
		self.titleView.numberOfLines = 2
		self.titleView.textAlignment = .Center
		self.titleView.isAccessibilityElement = false
		self.titleView.textColor = self.navigationController?.navigationBar.tintColor
		self.navigationItem.titleView = self.titleView
	}

	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)

		if self.artist.albums.count <= 0
		{
			MPDDataSource.shared.getAlbumsForArtist(artist, callback:{
				dispatch_async(dispatch_get_main_queue()) {
					self.tableView.reloadData()
					self._updateNavigationTitle()
				}
			})
		}

		self._updateNavigationTitle()
	}

	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
	{
		return .Portrait
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle
	{
		return .LightContent
	}

	// MARK: - Private
	private func _updateNavigationTitle()
	{
		let attrs = NSMutableAttributedString(string:self.artist.name + "\n", attributes:[NSFontAttributeName : UIFont(name:"HelveticaNeue-Medium", size:14.0)!])
		attrs.appendAttributedString(NSAttributedString(string:"\(self.artist.albums.count) \(self.artist.albums.count > 1 ? NYXLocalizedString("lbl_albums").lowercaseString : NYXLocalizedString("lbl_album").lowercaseString)", attributes:[NSFontAttributeName : UIFont(name:"HelveticaNeue", size:13.0)!]))
		self.titleView.attributedText = attrs
	}
}

// MARK: - UITableViewDataSource
extension AlbumsVC
{
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return self.artist.albums.count + 1 // dummy
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCellWithIdentifier("io.whine.mpdremote.cell.album", forIndexPath:indexPath) as! AlbumTableViewCell

		// Dummy to let some space for the mini player
		if indexPath.row == self.artist.albums.count
		{
			cell.coverView.image = nil
			cell.lblAlbum.text = ""
			cell.separator.hidden = true
			cell.accessoryType = .None
			cell.selectionStyle = .None
			return cell
		}

		let album = self.artist.albums[indexPath.row]
		cell.lblAlbum.text = album.name
		cell.separator.hidden = false
		cell.accessoryType = .DisclosureIndicator
		cell.accessibilityLabel = "\(album.name)"

		// No server for covers
		if NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefWEBServer) == nil
		{
			let bgColor = UIColor.fromRGB(album.name.djb2())
			let fontColor = bgColor.inverseColor()
			cell.coverView.image = UIImage.fromString(album.name, font:UIFont(name:"Chalkduster", size:16.0)!, fontColor:fontColor, backgroundColor:bgColor, maxSize:cell.coverView.size)
			return cell
		}

		// No cover, abort
		if !album.hasCover
		{
			cell.coverView.image = UIImage(named:"default-cover")
			return cell
		}

		// Get local URL for cover
		guard let coverURL = album.localCoverURL else
		{
			Logger.alog("[!] No cover URL for \(album)") // should not happen
			cell.coverView.image = UIImage(named:"default-cover")
			return cell
		}

		if let cover = UIImage.loadFromURL(coverURL)
		{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
				let cropped = cover.imageCroppedToFitSize(cell.coverView.size)
				dispatch_async(dispatch_get_main_queue()) {
					if let c = self.tableView.cellForRowAtIndexPath(indexPath) as? AlbumTableViewCell
					{
						c.coverView.image = cropped
					}
				}
			}
		}
		else
		{
			cell.coverView.image = UIImage(named:"default-cover")
			let sizeAsData = NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefCoverSize)!
			let cropSize = NSKeyedUnarchiver.unarchiveObjectWithData(sizeAsData) as! NSValue
			if album.path != nil
			{
				self._downloadCoverForAlbum(album, cropSize:cropSize.CGSizeValue(), callback:{ (thumbnail: UIImage) in
					let cropped = thumbnail.imageCroppedToFitSize(cell.coverView.size)
					dispatch_async(dispatch_get_main_queue()) {
						if let c = self.tableView.cellForRowAtIndexPath(indexPath) as? AlbumTableViewCell
						{
							c.coverView.image = cropped
						}
					}
				})
			}
			else
			{
				MPDDataSource.shared.getPathForAlbum(album, callback: {
					self._downloadCoverForAlbum(album, cropSize:cropSize.CGSizeValue(), callback:{ (thumbnail: UIImage) in
						let cropped = thumbnail.imageCroppedToFitSize(cell.coverView.size)
						dispatch_async(dispatch_get_main_queue()) {
							if let c = self.tableView.cellForRowAtIndexPath(indexPath) as? AlbumTableViewCell
							{
								c.coverView.image = cropped
							}
						}
					})
				})
			}
		}

		return cell
	}

	private func _downloadCoverForAlbum(album: Album, cropSize: CGSize, callback:(thumbnail: UIImage) -> Void)
	{
		let downloadOperation = DownloadCoverOperation(album:album, cropSize:cropSize)
		let key = album.name + album.year
		weak var weakOperation = downloadOperation
		downloadOperation.cplBlock = {(cover: UIImage, thumbnail: UIImage) in
			if let op = weakOperation
			{
				if !op.cancelled
				{
					self._downloadOperations.removeValueForKey(key)
				}
			}
			callback(thumbnail:thumbnail)
		}
		self._downloadOperations[key] = downloadOperation
		APP_DELEGATE().operationQueue.addOperation(downloadOperation)
	}
}

// MARK: - UITableViewDelegate
extension AlbumsVC
{
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		// Dummy, ignore
		if indexPath.row == self.artist.albums.count
		{
			return
		}

		// Set data according to search state
		let vc = AlbumDetailVC()
		vc.selectedIndex = indexPath.row
		vc.albums = self.artist.albums
		self.navigationController?.pushViewController(vc, animated:true)

		tableView.deselectRowAtIndexPath(indexPath, animated:true)
	}

	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
	{
		let c = cell as! AlbumTableViewCell
		c.coverView.frame = CGRect(5.0, (c.height - c.coverView.height) * 0.5, c.coverView.size)
		c.lblAlbum.frame = CGRect(c.coverView.right + 10.0, c.coverView.y, c.width - c.coverView.right - 40.0, c.lblAlbum.height)
		c.separator.frame = CGRect(0.0, c.height - c.separator.height, c.width, c.separator.height)
	}
	
	override func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
	{
		// Dummy, ignore
		if indexPath.row == self.artist.albums.count
		{
			return
		}

		// Remove download cover operation if still in queue
		let album = self.artist.albums[indexPath.row]
		let key = album.name + album.year
		if let op = self._downloadOperations[key] as! DownloadCoverOperation?
		{
			op.cancel()
			self._downloadOperations.removeValueForKey(key)
			Logger.dlog("[+] Cancelling \(op)")
		}
	}

	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
	{
		if indexPath.row == self.artist.albums.count
		{
			return 44.0 // dummy cell
		}
		return 74.0
	}
}