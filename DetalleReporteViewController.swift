import UIKit
import PhotosUI

final class DetalleReporteViewController: UIViewController {

    @IBOutlet weak var botonCategoria: UIButton!
    @IBOutlet weak var botonFoto: UIButton!
    @IBOutlet weak var etiquetaEstado: UILabel?
    @IBOutlet weak var etiquetaDetalleEstado: UILabel?
    @IBOutlet weak var campoURL: UITextField?
    @IBOutlet weak var campoDescripcion: UITextView?

    @IBAction func cerrarPantalla(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func actualizarReporte(_ sender: Any) {
        guard validarCampos() else { return }

        avisar(titulo: "Reporte actualizado",
               mensaje: "Los cambios se guardaron correctamente.") { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    @IBAction func eliminarReporte(_ sender: Any) {
        let alerta = UIAlertController(
            title: "¿Eliminar este reporte?",
            message: "Esta acción no se puede deshacer.",
            preferredStyle: .alert
        )

        alerta.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alerta.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
            self?.dismiss(animated: true)
        })

        present(alerta, animated: true)
    }

    private let categorias = [
        "Hoteles y viajes",
        "Electrónicos",
        "Empleos",
        "Vehículos",
        "Boletos para eventos"
    ]

    private let alturaOpcion: CGFloat = 44
    private let tamañoLetra: CGFloat = 16
    private let colorFondoOpcion = UIColor(red: 0.91, green: 0.91, blue: 0.92, alpha: 1)

    private var botonesOpcion: [UIButton] = []
    private var desplegado = false

    private(set) var categoriaSeleccionada: String?
    private(set) var fotoSeleccionada: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        prepararSelector()
        prepararBotonFoto()
    }

    private func prepararSelector() {
        guard let stack = botonCategoria.superview as? UIStackView,
              let indice = stack.arrangedSubviews.firstIndex(of: botonCategoria)
        else {
            print("⚠️ El botón de categoría no está dentro de un Stack View.")
            return
        }

        botonCategoria.addTarget(self, action: #selector(alternarLista),
                                 for: .touchUpInside)

        for (i, nombre) in categorias.enumerated() {
            let opcion = crearOpcion(titulo: nombre)
            opcion.tag = i
            opcion.addTarget(self, action: #selector(elegirCategoria(_:)),
                             for: .touchUpInside)
            opcion.isHidden = true
            opcion.alpha = 0

            botonesOpcion.append(opcion)
            stack.insertArrangedSubview(opcion, at: indice + 1 + i)
        }
    }

    private func crearOpcion(titulo: String) -> UIButton {
        let boton = UIButton(type: .system)

        var config = UIButton.Configuration.filled()
        config.title = titulo
        config.baseBackgroundColor = colorFondoOpcion
        config.baseForegroundColor = .black
        config.cornerStyle = .fixed
        config.background.cornerRadius = 8
        config.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { [weak self] entrada in
                var salida = entrada
                salida.font = .systemFont(ofSize: self?.tamañoLetra ?? 16)
                return salida
            }
        boton.configuration = config
        boton.heightAnchor.constraint(equalToConstant: alturaOpcion).isActive = true
        return boton
    }

    @objc private func alternarLista() {
        desplegado.toggle()
        animarOpciones(visibles: desplegado)
    }

    @objc private func elegirCategoria(_ boton: UIButton) {
        let elegida = categorias[boton.tag]
        categoriaSeleccionada = elegida
        ponerTitulo(elegida, en: botonCategoria, color: .black)
        desplegado = false
        animarOpciones(visibles: false)
    }

    private func animarOpciones(visibles: Bool) {
        UIView.animate(withDuration: 0.25) {
            self.botonesOpcion.forEach {
                $0.isHidden = !visibles
                $0.alpha = visibles ? 1 : 0
            }
            self.view.layoutIfNeeded()
        }
    }

    private func prepararBotonFoto() {
        botonFoto.addTarget(self, action: #selector(tocarFoto), for: .touchUpInside)
        botonFoto.configuration?.background.imageContentMode = .scaleAspectFill
        botonFoto.clipsToBounds = true
    }

    @objc private func tocarFoto() {
        let hoja = UIAlertController(title: "Foto de evidencia",
                                     message: nil,
                                     preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            hoja.addAction(UIAlertAction(title: "Tomar foto", style: .default) { [weak self] _ in
                self?.abrirCamara()
            })
        }

        hoja.addAction(UIAlertAction(title: "Elegir de la galería", style: .default) { [weak self] _ in
            self?.abrirGaleria()
        })

        if fotoSeleccionada != nil {
            hoja.addAction(UIAlertAction(title: "Quitar foto", style: .destructive) { [weak self] _ in
                self?.mostrarFoto(nil)
            })
        }

        hoja.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        hoja.popoverPresentationController?.sourceView = botonFoto
        hoja.popoverPresentationController?.sourceRect = botonFoto.bounds
        present(hoja, animated: true)
    }

    private func abrirCamara() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    private func abrirGaleria() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func mostrarFoto(_ imagen: UIImage?) {
        fotoSeleccionada = imagen

        if let imagen {
            botonFoto.configuration?.background.image = imagen
            botonFoto.configuration?.title = nil
            botonFoto.configuration?.image = nil
        } else {
            botonFoto.configuration?.background.image = nil
            botonFoto.configuration?.title = "Toma foto o sube imagen"
            botonFoto.configuration?.image = UIImage(systemName: "camera.fill")
        }
    }

    private func ponerTitulo(_ texto: String, en boton: UIButton, color: UIColor) {
        if boton.configuration != nil {
            boton.configuration?.title = texto
            boton.configuration?.baseForegroundColor = color
        } else {
            boton.setTitle(texto, for: .normal)
            boton.setTitleColor(color, for: .normal)
        }
    }

    private func validarCampos() -> Bool {
        let url = campoURL?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard campoURL != nil else { return true }

        if url.isEmpty {
            avisar(titulo: "Falta la URL",
                   mensaje: "Escribe la dirección de la oferta falsa.")
            return false
        }
        return true
    }

    private func avisar(titulo: String,
                        mensaje: String,
                        alCerrar: (() -> Void)? = nil) {
        let alerta = UIAlertController(title: titulo,
                                       message: mensaje,
                                       preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            alCerrar?()
        })
        present(alerta, animated: true)
    }
}

extension DetalleReporteViewController: UIImagePickerControllerDelegate,
                                        UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        let imagen = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        if let imagen { mostrarFoto(imagen) }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension DetalleReporteViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController,
                didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let proveedor = results.first?.itemProvider,
              proveedor.canLoadObject(ofClass: UIImage.self) else { return }

        proveedor.loadObject(ofClass: UIImage.self) { [weak self] objeto, error in
            guard let imagen = objeto as? UIImage else {
                if let error { print("No se pudo cargar la imagen:", error) }
                return
            }
            DispatchQueue.main.async {
                self?.mostrarFoto(imagen)
            }
        }
    }
}
