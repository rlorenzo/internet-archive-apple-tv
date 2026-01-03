//
//  AlbumArtView.swift
//  Internet Archive
//
//  Large album art display with subtle reflection effect for Now Playing screen
//

import UIKit
import AlamofireImage

/// Large album art view with reflection effect for the Now Playing screen
@MainActor
final class AlbumArtView: UIView {

    // MARK: - Properties

    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        view.backgroundColor = UIColor.systemGray.withAlphaComponent(0.2)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let placeholderImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = UIColor.systemGray
        view.image = UIImage(systemName: "music.note")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let reflectionImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.alpha = 0.25
        view.transform = CGAffineTransform(scaleX: 1, y: -1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let reflectionGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.cgColor
        ]
        layer.locations = [0, 0.7]
        return layer
    }()

    /// The size of the album art image
    private let artSize: CGFloat

    // MARK: - Initialization

    init(size: CGFloat = 400) {
        self.artSize = size
        super.init(frame: .zero)
        setupViews()
    }

    override init(frame: CGRect) {
        self.artSize = 400
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        self.artSize = 400
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        addSubview(reflectionImageView)
        addSubview(imageView)
        imageView.addSubview(placeholderImageView)

        reflectionImageView.layer.mask = reflectionGradientLayer

        NSLayoutConstraint.activate([
            // Main image
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: artSize),
            imageView.heightAnchor.constraint(equalToConstant: artSize),

            // Placeholder centered in image view
            placeholderImageView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            placeholderImageView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            placeholderImageView.widthAnchor.constraint(equalToConstant: artSize * 0.4),
            placeholderImageView.heightAnchor.constraint(equalToConstant: artSize * 0.4),

            // Reflection below main image
            reflectionImageView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            reflectionImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            reflectionImageView.widthAnchor.constraint(equalTo: imageView.widthAnchor),
            reflectionImageView.heightAnchor.constraint(equalToConstant: artSize * 0.25)
        ])

        // Setup accessibility
        isAccessibilityElement = true
        accessibilityLabel = "Album artwork"
        accessibilityTraits = .image
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        reflectionGradientLayer.frame = reflectionImageView.bounds
    }

    // MARK: - Configuration

    /// Set the album art image from a URL
    /// - Parameter url: URL to the image, or nil to show placeholder
    func setImage(url: URL?) {
        guard let url = url else {
            showPlaceholder()
            return
        }

        imageView.af.setImage(
            withURL: url,
            placeholderImage: nil,
            imageTransition: .crossDissolve(0.3)
        ) { [weak self] response in
            switch response.result {
            case .success(let image):
                self?.placeholderImageView.isHidden = true
                self?.reflectionImageView.image = image
                self?.accessibilityLabel = "Album artwork loaded"
            case .failure:
                self?.showPlaceholder()
            }
        }
    }

    /// Set the album art directly from an image
    /// - Parameter image: The image to display
    func setImage(_ image: UIImage?) {
        if let image = image {
            imageView.image = image
            reflectionImageView.image = image
            placeholderImageView.isHidden = true
            accessibilityLabel = "Album artwork"
        } else {
            showPlaceholder()
        }
    }

    private func showPlaceholder() {
        imageView.image = nil
        reflectionImageView.image = nil
        placeholderImageView.isHidden = false
        accessibilityLabel = "Album artwork placeholder"
    }

    // MARK: - Animation

    /// Animate a subtle pulse effect (e.g., when track changes)
    func animatePulse() {
        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                self.imageView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            },
            completion: { _ in
                UIView.animate(
                    withDuration: 0.15,
                    delay: 0,
                    options: [.curveEaseInOut],
                    animations: {
                        self.imageView.transform = .identity
                    }
                )
            }
        )
    }
}
